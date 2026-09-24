// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AtlasDesign",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "AtlasDesign", targets: ["AtlasDesign"])],
    dependencies: [
        .package(path: "../AtlasDomain")
    ],
    targets: [
        .target(
            name: "AtlasDesign",
            dependencies: [
                .product(name: "AtlasDomain", package: "atlasdomain")
            ]
        )
    ]
)

