// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Base64",
    platforms: [
        .macOS("13.5")
    ],
    products: [
        .library(name: "Base64", type: .dynamic, targets: ["Base64"])
    ],
    dependencies: [
        .package(name: "swift-nif", path: "../../..")
    ],
    targets: [
        .target(
            name: "Base64",
            dependencies: [
                .product(name: "NIF", package: "swift-nif")
            ]
        )
    ]
)
