// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Colors",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(name: "Colors", targets: ["Colors"]),
    ], dependencies: [
        .package(url: "https://github.com/akalhawas/SharedLibraries.git", from: "0.1.3"),
    ],
    targets: [
        .target(
            name: "Colors",
            dependencies: [
                .product(name: "Navigation", package: "SharedLibraries"),
                .product(name: "NetworkService", package: "SharedLibraries"),
            ]
        ),
        .testTarget(
            name: "ColorsTests",
            dependencies: [
                "Colors",
                .product(name: "NetworkService", package: "SharedLibraries"),
            ]
        ),
    ]
)
