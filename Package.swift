// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport
import Foundation

let package = Package(
    name: "swift-nif",
    platforms: [.macOS("13.5")],
    products: [
        .library(name: "NIF", targets: ["NIF"]), .library(name: "NIFSupport", targets: ["NIFSupport"]),
        .library(name: "CErlang", targets: ["CErlang"]),
    ],
    dependencies: [.package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")],
    targets: [
        .target(
            name: "NIF",
            dependencies: ["NIFSupport"],
            linkerSettings: [.unsafeFlags(["-Xlinker", "-undefined", "-Xlinker", "dynamic_lookup"])]
        ),

        .macro(
            name: "NIFMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),

        .target(name: "NIFSupport", dependencies: ["CErlang", "NIFMacros"]),
        .target(name: "CErlang"),
    ]
)
