// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AtlasDomain",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "AtlasDomain", targets: ["AtlasDomain"])],
    dependencies: [],
    targets: [
        .target(
            name: "AtlasDomain",
            dependencies: []
        )
    ]
)

