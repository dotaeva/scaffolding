// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AtlasAppFeature",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "AtlasAppFeature", targets: ["AtlasAppFeature"])],
    dependencies: [
        .package(path: "../AtlasDomain"),
        .package(path: "../AtlasDesign"),
        .package(path: "../AtlasWelcome"),
        .package(path: "../AtlasShell"),
        .package(path: "../AtlasExplore"),
        .package(path: "../AtlasPlaces"),
        .package(path: "../AtlasSaved"),
        .package(path: "../../../..")
    ],
    targets: [
        .target(
            name: "AtlasAppFeature",
            dependencies: [
                .product(name: "AtlasDomain", package: "atlasdomain"),
                .product(name: "AtlasDesign", package: "atlasdesign"),
                .product(name: "AtlasWelcome", package: "atlaswelcome"),
                .product(name: "AtlasShell", package: "atlasshell"),
                .product(name: "AtlasExplore", package: "atlasexplore"),
                .product(name: "AtlasPlaces", package: "atlasplaces"),
                .product(name: "AtlasSaved", package: "atlassaved"),
                .product(name: "Scaffolding", package: "scaffolding")
            ]
        )
    ]
)

