// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AtlasLab",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "AtlasLab", targets: ["AtlasLab"])],
    dependencies: [
        .package(path: "../AtlasDomain"),
        .package(path: "../AtlasDesign"),
        .package(path: "../AtlasPlanner"),
        .package(path: "../../../..")
    ],
    targets: [
        .target(
            name: "AtlasLab",
            dependencies: [
                .product(name: "AtlasDomain", package: "atlasdomain"),
                .product(name: "AtlasDesign", package: "atlasdesign"),
                .product(name: "AtlasPlanner", package: "atlasplanner"),
                .product(name: "Scaffolding", package: "scaffolding")
            ]
        )
    ]
)

