# Atlas project conventions

- Every feature and shared module is a separate Swift package under `Packages/`, with its own `Package.swift`, library product, and `Sources/<Module>/` directory.
- Declare dependencies as local packages and consume their explicit library products. Keep the dependency graph directed from app composition to features to shared modules.
- Keep feature screens internal and expose coordinators as the feature API. Navigation state belongs to coordinators, following the repository's Scaffolding guide.
- Maintain `Atlas.xcodeproj` and its shared schemes directly. Do not use XcodeGen or introduce a project-generation configuration.
- The app target links only `AtlasAppFeature`. Cross-feature tests belong to the separate `AtlasIntegrationTests` package; UI tests use the app's native Xcode test target.
- Run the cross-package suite with `swift test --package-path Example/Atlas/Packages/AtlasIntegrationTests` from the repository root. Check the Xcode project on macOS and iOS after changing package wiring.
