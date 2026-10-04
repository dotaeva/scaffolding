#!/usr/bin/env python3
"""Compile checked-in consumers and platform modules after swift build/test."""
from pathlib import Path
import argparse
import platform
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
FIXTURES = ROOT / "Tests/CompileFixtures"
EXPECTED_ERRORS = {
    "opaque_parameter": "Scaffolding routes cannot be generic",
    "readonly_storage": "setter is inaccessible",
    "readonly_erased_storage": "get-only property",
    "deprecated_replace_last": "is deprecated",
    "deprecated_sheet_factory": "Use .sheet and apply presentationDetents(_:)",
    "deprecated_sheet_configuration": "Apply SwiftUI presentation modifiers to the presented view",
    "deprecated_modal_configuration": "Native modifiers are not reflected in this property",
    "overloaded_routes": "Scaffolding routes must have unique names",
    "nonliteral_argument": "requires a literal true or false",
    "generic_route": "Scaffolding routes cannot be generic",
    "async_route": "must be synchronous and nonthrowing",
    "sending_non_sendable": "risks causing data races",
}


def run(command):
    return subprocess.run(command, cwd=ROOT, text=True, capture_output=True)


def checked(command):
    result = run(command)
    if result.returncode:
        raise SystemExit(result.stdout + result.stderr)
    return result.stdout.strip()


def validate(mode):
    binary = Path(checked(["swift", "build", "--show-bin-path"]))
    modules = next((p for p in [binary / "Modules", binary]
                    if (p / "Scaffolding.swiftmodule").exists()), None)
    plugin = next((p for p in [binary / "ScaffoldingMacros-tool", binary / "ScaffoldingMacros"]
                   if p.is_file()), None)
    if modules is None or plugin is None:
        raise SystemExit("Missing build artifacts; run swift build first.")
    sources = sorted(FIXTURES.glob("*.swift"))
    if not sources:
        raise SystemExit(f"No consumer fixtures found in {FIXTURES}")
    base = ["xcrun", "swiftc", "-parse-as-library", "-swift-version", "6",
            "-load-plugin-executable", str(plugin) + "#ScaffoldingMacros"]
    failed = False
    with tempfile.TemporaryDirectory(prefix="scaffolding-validation-") as temporary:
        if mode == "consumers":
            for source in sources:
                command = base + ["-typecheck", "-module-name", "ScaffoldingConsumer",
                                  "-package-name", "ScaffoldingConsumer", "-target",
                                  f"{platform.machine()}-apple-macosx15.0", "-I", str(modules),
                                  "-module-cache-path", temporary, str(source)]
                if source.stem.startswith("sending_"):
                    # Region isolation diagnostics run during SIL generation,
                    # after the stage covered by a plain type-check.
                    command[command.index("-typecheck")] = "-emit-sil"
                    command += ["-o", str(Path(temporary) / (source.stem + ".sil"))]
                result = run(command)
                output = result.stdout + result.stderr
                expected = EXPECTED_ERRORS.get(source.stem)
                if source.stem.startswith("deprecated_"):
                    compatible = result.returncode == 0 and expected in output
                    strict = run(command + ["-warnings-as-errors"])
                    passed = compatible and strict.returncode != 0 and expected in strict.stderr
                    output += strict.stdout + strict.stderr
                elif expected:
                    passed = result.returncode != 0 and expected in output
                else:
                    passed = result.returncode == 0
                print(f"{source.name}: {'PASS' if passed else 'FAIL'}", flush=True)
                if not passed:
                    failed = True
                    print(output)
        else:
            arch = platform.machine()
            targets = [
                ("macosx", f"{arch}-apple-macosx15.0"),
                ("iphonesimulator", f"{arch}-apple-ios18.0-simulator"),
                ("macosx", f"{arch}-apple-ios18.0-macabi"),
                ("appletvsimulator", f"{arch}-apple-tvos18.0-simulator"),
                ("watchsimulator", "arm64-apple-watchos11.0-simulator"),
            ]
            library = [str(p) for p in sorted((ROOT / "Sources/Scaffolding").rglob("*.swift"))
                       if "Scaffolding.docc" not in p.parts]
            for sdk_name, target in targets:
                output_dir = Path(temporary) / target
                output_dir.mkdir()
                sdk = Path(checked(["xcrun", "--sdk", sdk_name, "--show-sdk-path"]))
                command = base + ["-emit-module", "-module-name", "Scaffolding",
                                  "-emit-module-path", str(output_dir / "Scaffolding.swiftmodule"),
                                  "-sdk", str(sdk), "-target", target,
                                  "-module-cache-path", str(output_dir), "-warnings-as-errors"]
                if target.endswith("macabi"):
                    command += ["-F", str(sdk / "System/iOSSupport/System/Library/Frameworks"),
                                "-I", str(sdk / "System/iOSSupport/usr/include")]
                result = run(command + library)
                print(f"{target}: {'PASS' if result.returncode == 0 else 'FAIL'}", flush=True)
                if result.returncode:
                    failed = True
                    print(result.stdout + result.stderr)
                    continue
                for name in ["baseline.swift", "conditional_routes.swift", "availability_routes.swift",
                             "conditional_aliases.swift", "payload_hygiene.swift", "sending_payload.swift"]:
                    consumer = base + ["-typecheck", "-module-name", "PlatformConsumer",
                                       "-package-name", "ScaffoldingConsumer", "-sdk", str(sdk),
                                       "-target", target, "-I", str(output_dir),
                                       "-module-cache-path", str(output_dir), str(FIXTURES / name)]
                    if target.endswith("macabi"):
                        consumer += ["-F", str(sdk / "System/iOSSupport/System/Library/Frameworks"),
                                     "-I", str(sdk / "System/iOSSupport/usr/include")]
                    result = run(consumer)
                    print(f"  {name}: {'PASS' if result.returncode == 0 else 'FAIL'}", flush=True)
                    if result.returncode:
                        failed = True
                        print(result.stdout + result.stderr)
    return 1 if failed else 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["consumers", "platforms"])
    raise SystemExit(validate(parser.parse_args().mode))
