// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CameraCore",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(
            name: "CameraCore",
            targets: ["CameraCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Hideyuki-Machida/MetalCanvas", .branch("spm")),
        .package(url: "https://github.com/Hideyuki-Machida/ProcessLogger.Swift", .branch("master"))
    ],
    targets: [
        .target(
            name: "CameraCore",
            dependencies: ["MetalCanvas", "ProcessLogger.Swift"]
        ),
        .testTarget(
            name: "CameraCoreTests",
            dependencies: ["CameraCore"]),
    ]
)
