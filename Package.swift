// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProjectCoordinator",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "project-coordinator",
            targets: ["project-coordinator"]
        ),
        .library(
            name: "ProjectCoordinator",
            targets: ["ProjectCoordinator"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.11.0"),
    ],
    targets: [
        .target(
            name: "ProjectCoordinator",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
            ],
            path: "Sources/ProjectCoordinator"
        ),
        .executableTarget(
            name: "project-coordinator",
            dependencies: [
                "ProjectCoordinator",
                .product(name: "MCP", package: "swift-sdk"),
            ],
            path: "Sources/project-coordinator"
        ),
        .testTarget(
            name: "ProjectCoordinatorTests",
            dependencies: ["ProjectCoordinator"],
            path: "Tests/ProjectCoordinatorTests"
        ),
    ]
)
