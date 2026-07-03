// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DicyaninHumanoidMesh",
    platforms: [
        .visionOS(.v2),
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "DicyaninHumanoidMesh",
            targets: ["DicyaninHumanoidMesh"]
        )
    ],
    targets: [
        .target(
            name: "DicyaninHumanoidMesh"
        ),
        .testTarget(
            name: "DicyaninHumanoidMeshTests",
            dependencies: ["DicyaninHumanoidMesh"]
        )
    ]
)
