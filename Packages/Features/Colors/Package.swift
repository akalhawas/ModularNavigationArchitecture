// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Colors",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(name: "Colors", targets: ["Colors"]),
    ], dependencies: [
        .package(url: "https://github.com/akalhawas/SharedLibraries.git", from: "0.1.5"),
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
