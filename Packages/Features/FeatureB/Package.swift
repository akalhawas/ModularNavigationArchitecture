// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FeatureB",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "FeatureB",
            targets: ["FeatureB"]
        ),
    ], dependencies: [
        .package(path: "../../Navigation/Navigation"),
        .package(path: "../../NavigationDestinations/NavigationDestinations")
    ],
    targets: [
        .target(
            name: "FeatureB",
            dependencies: [
                "Navigation",
                "NavigationDestinations"
            ]
        ),
    ]
)
