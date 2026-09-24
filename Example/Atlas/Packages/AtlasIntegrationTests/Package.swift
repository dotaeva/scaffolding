// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AtlasIntegrationTests",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [],
    dependencies: [
        .package(path: "../AtlasAppFeature"),
        .package(path: "../AtlasDomain"),
        .package(path: "../AtlasShell"),
        .package(path: "../AtlasExplore"),
        .package(path: "../AtlasPlaces"),
        .package(path: "../AtlasSaved"),
        .package(path: "../AtlasPlanner"),
        .package(path: "../AtlasLab"),
        .package(path: "../AtlasWelcome"),
        .package(path: "../../../..")
    ],
    targets: [
        .testTarget(
            name: "AtlasIntegrationTests",
            dependencies: [
                .product(name: "AtlasAppFeature", package: "atlasappfeature"),
                .product(name: "AtlasDomain", package: "atlasdomain"),
                .product(name: "AtlasShell", package: "atlasshell"),
                .product(name: "AtlasExplore", package: "atlasexplore"),
                .product(name: "AtlasPlaces", package: "atlasplaces"),
                .product(name: "AtlasSaved", package: "atlassaved"),
                .product(name: "AtlasPlanner", package: "atlasplanner"),
                .product(name: "AtlasLab", package: "atlaslab"),
                .product(name: "AtlasWelcome", package: "atlaswelcome"),
                .product(name: "Scaffolding", package: "scaffolding"),
                .product(name: "ScaffoldingTesting", package: "scaffolding")
            ]
        )
    ]
)

