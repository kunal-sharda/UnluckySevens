// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ULS_Transport",
    products: [
        .library(
            name: "ULS_Transport",
            targets: ["ULS_Transport"]
        ),
    ],
    dependencies: [
        .package(path: "../ULS_CoreGame"),
    ],
    targets: [
        .target(
            name: "ULS_Transport"
        ),
        .testTarget(
            name: "ULS_TransportTests",
            dependencies: [
                "ULS_Transport",
                .product(name: "ULS_CoreGame", package: "ULS_CoreGame"),
            ]
        ),
    ]
)
