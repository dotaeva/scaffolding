// Package.swift — for an SPM app. In an Xcode project, add ScaffoldingTesting
// under the test target's General ▸ Frameworks and Libraries instead.
.testTarget(
    name: "PlanetsTests",
    dependencies: [
        "Planets",
        // Test-only helpers: activated(), descendant(ofType:),
        // hierarchyContains(_:_:as:), waitUntil. Never link this into the app
        // target — it imports Swift Testing.
        .product(name: "ScaffoldingTesting", package: "scaffolding"),
    ]
)
