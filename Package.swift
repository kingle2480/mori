// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Mori",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "Mori", targets: ["Mori"]),
    ],
    dependencies: [
        .package(path: "Packages/MoriCore"),
        .package(path: "Packages/MoriPersistence"),
    ],
    targets: [
        .executableTarget(
            name: "Mori",
            dependencies: [
                "MoriCore",
                "MoriPersistence",
            ],
            path: "Sources/Mori"
        ),
    ]
)
