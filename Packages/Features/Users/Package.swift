// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Users",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(name: "UsersAPI", targets: ["UsersAPI"]),
        .library(name: "Users", targets: ["Users"]),
    ], dependencies: [
        .package(url: "https://github.com/akalhawas/SharedLibraries.git", from: "0.1.0"),
        .package(path: "../Colors"),
    ],
    targets: [
        .target(
            name: "UsersAPI",
            dependencies: [.product(name: "Navigation", package: "SharedLibraries")]
        ),
        .target(
            name: "Users",
            dependencies: [
                "UsersAPI",
                .product(name: "Navigation", package: "SharedLibraries"),
                .product(name: "NetworkService", package: "SharedLibraries"),
                .product(name: "ColorsAPI", package: "Colors"),
            ]
        ),
        .testTarget(
            name: "UsersTests",
            dependencies: [
                "Users",
                .product(name: "NetworkService", package: "SharedLibraries"),
            ]
        ),
    ]
)
