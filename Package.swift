// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Scaffolding",
    platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18), .watchOS(.v11), .macCatalyst(.v18)],
    products: [
        // Products define the executables∫ and libraries a package produces, making them visible to other packages.
        .library(
            name: "Scaffolding",
            targets: ["Scaffolding"]
        ),
        // Test-only helpers for asserting on coordinators. Link this from a
        // test target, never from an app target — it imports Swift Testing.
        .library(
            name: "ScaffoldingTesting",
            targets: ["ScaffoldingTesting"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.1"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.5"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "ScaffoldingMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "Scaffolding", dependencies: ["ScaffoldingMacros"]),

        .target(name: "ScaffoldingTesting", dependencies: ["Scaffolding"]),

        .testTarget(
            name: "ScaffoldingTests",
            dependencies: ["Scaffolding", "ScaffoldingTesting"]
        ),
    ]
)
