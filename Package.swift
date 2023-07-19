// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MQVMRunner",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .executable(
            name: "MQVMRunner",
            targets: ["MQVMRunner"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/miquido/MQ-iOS.git", .upToNextMajor(from: "0.11.0")),
        .package(url: "https://github.com/orlandos-nl/Citadel", from: "0.4.13"),
        .package(url: "https://github.com/apple/swift-format", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "MQVMRunner",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "MQ", package: "MQ-iOS"),
                .product(name: "Citadel", package: "Citadel")
            ]
        ),
        .testTarget(
            name: "MQVMRunnerTests",
            dependencies: [
                "MQVMRunner",
                .product(name: "MQ", package: "MQ-iOS")
            ]
        )
    ]
)
