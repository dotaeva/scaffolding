// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AtlasPlanner",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "AtlasPlanner", targets: ["AtlasPlanner"])],
    dependencies: [
        .package(path: "../AtlasDomain"),
        .package(path: "../AtlasDesign"),
        .package(path: "../../../..")
    ],
    targets: [
        .target(
            name: "AtlasPlanner",
            dependencies: [
                .product(name: "AtlasDomain", package: "atlasdomain"),
                .product(name: "AtlasDesign", package: "atlasdesign"),
                .product(name: "Scaffolding", package: "scaffolding")
            ]
        )
    ]
)

