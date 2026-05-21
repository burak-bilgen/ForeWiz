// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WizPathKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "WizPathKit",
            targets: ["WizPathKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WizPathKit",
            dependencies: []
        ),
    ]
)
