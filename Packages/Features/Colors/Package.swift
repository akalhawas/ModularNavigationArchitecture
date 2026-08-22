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
        .package(path: "/Users/akalhawas/Desktop/Wajha-Project/SharedLibrary/SharedLibraries"),
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
