// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NavigationDestinations",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "NavigationDestinations",
            targets: ["NavigationDestinations"]
        ),
    ], dependencies: [
        .package(path: "../../Navigation/Navigation")
    ],
    targets: [
        .target(
            name: "NavigationDestinations",
            dependencies: [
                "Navigation"
            ]
        ),
    ]
)
