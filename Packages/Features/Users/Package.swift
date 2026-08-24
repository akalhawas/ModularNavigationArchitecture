// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Users",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(name: "Users", targets: ["Users"]),
    ], dependencies: [
        .package(url: "https://github.com/akalhawas/SharedLibraries.git", from: "0.1.4"),
    ],
    targets: [
        .target(
            name: "Users",
            dependencies: [
                .product(name: "Navigation", package: "SharedLibraries"),
                .product(name: "NetworkService", package: "SharedLibraries"),
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
