// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AtlasPlaces",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "AtlasPlaces", targets: ["AtlasPlaces"])],
    dependencies: [
        .package(path: "../AtlasDomain"),
        .package(path: "../AtlasDesign"),
        .package(path: "../AtlasPlanner"),
        .package(path: "../../../..")
    ],
    targets: [
        .target(
            name: "AtlasPlaces",
            dependencies: [
                .product(name: "AtlasDomain", package: "atlasdomain"),
                .product(name: "AtlasDesign", package: "atlasdesign"),
                .product(name: "AtlasPlanner", package: "atlasplanner"),
                .product(name: "Scaffolding", package: "scaffolding")
            ]
        )
    ]
)

