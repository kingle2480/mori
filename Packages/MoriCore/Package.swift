// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MoriCore",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "MoriCore", targets: ["MoriCore"]),
    ],
    targets: [
        .target(
            name: "MoriCore",
            path: "Sources/MoriCore"
        ),
        .executableTarget(
            name: "MoriCoreTests",
            dependencies: ["MoriCore"],
            path: "Tests/MoriCoreTests"
        ),
    ]
)
