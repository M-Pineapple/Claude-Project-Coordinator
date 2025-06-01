// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ProjectCoordinator",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "project-coordinator",
            targets: ["ProjectCoordinator"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ProjectCoordinator",
            dependencies: []
        ),
        .testTarget(
            name: "ProjectCoordinatorTests",
            dependencies: ["ProjectCoordinator"],
            path: "Tests/ProjectCoordinatorTests"
        ),
    ]
)
