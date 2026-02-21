// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ULS_CoreGame",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "ULS_CoreGame",
            targets: ["ULS_CoreGame"]
        ),
    ],
    targets: [
        .target(
            name: "ULS_CoreGame"
        ),
        .testTarget(
            name: "ULS_CoreGameTests",
            dependencies: ["ULS_CoreGame"]
        ),
    ]
)
