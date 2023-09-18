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
        ),
        .library(
          name: "SimpleSSHClient",
          targets: ["SimpleSSHClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/miquido/MQ-iOS.git", .upToNextMajor(from: "0.11.0")),
        .package(url: "https://github.com/apple/swift-format", branch: "main"),
        .package(url: "https://github.com/pelece/BCrypt.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/Joannis/swift-nio-ssh.git", from: "0.3.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.7.0"),
    ],
    targets: [
        .target(name: "SimpleSSHClient", dependencies: [
            .product(name: "NIOSSH", package: "swift-nio-ssh"),
            .product(name: "CryptoSwift", package: "CryptoSwift"),
            .product(name: "BCrypt", package: "BCrypt"),
        ]),
        .executableTarget(
            name: "MQVMRunner",
            dependencies: [
                "SimpleSSHClient",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "MQ", package: "MQ-iOS"),
            ]
        ),
        .testTarget(
            name: "MQVMRunnerTests",
            dependencies: [
                "MQVMRunner",
                .product(name: "MQ", package: "MQ-iOS")
            ]
        ),
        .testTarget(
            name: "SimpleSSHClientTests",
            dependencies: [
                "SimpleSSHClient"
            ]
        )
    ]
)
