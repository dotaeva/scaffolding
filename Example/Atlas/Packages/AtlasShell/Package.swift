// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AtlasShell",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "AtlasShell", targets: ["AtlasShell"])],
    dependencies: [
        .package(path: "../AtlasDomain"),
        .package(path: "../AtlasDesign"),
        .package(path: "../AtlasExplore"),
        .package(path: "../AtlasSaved"),
        .package(path: "../AtlasPlaces"),
        .package(path: "../AtlasLab"),
        .package(path: "../../../..")
    ],
    targets: [
        .target(
            name: "AtlasShell",
            dependencies: [
                .product(name: "AtlasDomain", package: "atlasdomain"),
                .product(name: "AtlasDesign", package: "atlasdesign"),
                .product(name: "AtlasExplore", package: "atlasexplore"),
                .product(name: "AtlasSaved", package: "atlassaved"),
                .product(name: "AtlasPlaces", package: "atlasplaces"),
                .product(name: "AtlasLab", package: "atlaslab"),
                .product(name: "Scaffolding", package: "scaffolding")
            ]
        )
    ]
)

