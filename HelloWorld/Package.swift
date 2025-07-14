// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "HelloWorld",
    platforms: [.macOS(.v14), .iOS(.v17)],
    dependencies: [
        .package(
            url: "https://github.com/stackotter/swift-cross-ui",
            revision: "684b714410155223b9f54ca9d74867406c70009d"
        )
    ],
    targets: [
        .executableTarget(
            name: "HelloWorld",
            dependencies: [
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
                .product(name: "DefaultBackend", package: "swift-cross-ui")
            ]
        )
    ]
)
