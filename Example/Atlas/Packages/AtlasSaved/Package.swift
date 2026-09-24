// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AtlasSaved",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "AtlasSaved", targets: ["AtlasSaved"])],
    dependencies: [
        .package(path: "../AtlasDomain"),
        .package(path: "../AtlasDesign"),
        .package(path: "../AtlasPlaces"),
        .package(path: "../AtlasPlanner"),
        .package(path: "../../../..")
    ],
    targets: [
        .target(
            name: "AtlasSaved",
            dependencies: [
                .product(name: "AtlasDomain", package: "atlasdomain"),
                .product(name: "AtlasDesign", package: "atlasdesign"),
                .product(name: "AtlasPlaces", package: "atlasplaces"),
                .product(name: "AtlasPlanner", package: "atlasplanner"),
                .product(name: "Scaffolding", package: "scaffolding")
            ]
        )
    ]
)

