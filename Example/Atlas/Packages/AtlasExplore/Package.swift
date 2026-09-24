// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AtlasExplore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "AtlasExplore", targets: ["AtlasExplore"])],
    dependencies: [
        .package(path: "../AtlasDomain"),
        .package(path: "../AtlasDesign"),
        .package(path: "../AtlasPlaces"),
        .package(path: "../../../..")
    ],
    targets: [
        .target(
            name: "AtlasExplore",
            dependencies: [
                .product(name: "AtlasDomain", package: "atlasdomain"),
                .product(name: "AtlasDesign", package: "atlasdesign"),
                .product(name: "AtlasPlaces", package: "atlasplaces"),
                .product(name: "Scaffolding", package: "scaffolding")
            ]
        )
    ]
)

