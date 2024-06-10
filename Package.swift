// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MidiToolsSwift",
    products: [
        .library(
            name: "MidiToolsSwift",
            targets: ["MidiToolsSwift"]
        )
    ],
    dependencies: [
      .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
      .package(url: "https://github.com/maikudou/midi-manufacturers-swift", from: "1.0.0")
    ],
    targets: [
        .target(name: "MidiToolsSwift", dependencies: []),
        .executableTarget(
            name: "midi-tools",
            dependencies: [
                "MidiToolsSwift",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "MidiManufacturers", package: "midi-manufacturers-swift")
            ],
            path: "Sources/MidiToolsSwiftCli"
        ),
        .testTarget(
            name: "MidiToolsSwiftUnitTests",
            dependencies: ["MidiToolsSwift"]
        )
    ]
)
