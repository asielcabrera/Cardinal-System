// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cardinal-System",
    platforms: [.macOS(.v10_14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Cardinal-System",
            targets: ["Cardinal-System"]),
        .executable(name: "Run", targets: ["Run"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.62.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Cardinal-System",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
//                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                "Yams",
            ]
        ),
        .executableTarget(name: "Run",
                          dependencies: ["Cardinal-System"]
                         ),
        .testTarget(
            name: "Cardinal-SystemTests",
            dependencies: ["Cardinal-System"]),
    ]
)
