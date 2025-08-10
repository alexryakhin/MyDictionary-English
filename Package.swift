// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MyDictionary",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MyDictionary",
            targets: ["MyDictionary"]),
    ],
    dependencies: [
        .package(url: "https://github.com/RevenueCat/purchases-ios.git", exact: "4.0.0")
    ],
    targets: [
        .target(
            name: "MyDictionary",
            dependencies: [
                .product(name: "RevenueCat", package: "purchases-ios")
            ]),
        .testTarget(
            name: "MyDictionaryTests",
            dependencies: ["MyDictionary"]),
    ]
)
