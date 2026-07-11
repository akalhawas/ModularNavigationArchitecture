// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FeatureA",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "FeatureA",
            targets: ["FeatureA"]
        ),
    ], dependencies: [
        .package(path: "../../Navigation/Navigation"),
        .package(path: "../../NavigationDestinations/NavigationDestinations")
    ],
    targets: [
        .target(
            name: "FeatureA",
            dependencies: [
                "Navigation",
                "NavigationDestinations"
            ]
        ),
    ]
)
