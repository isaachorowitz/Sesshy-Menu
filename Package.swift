// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SessionMenu",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "SessionMenu",
            targets: ["SessionMenu"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-testing.git",
            revision: "5ee435b15ad40ec1f644b5eb9d247f263ccd2170"
        )
    ],
    targets: [
        .executableTarget(
            name: "SessionMenu",
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "SessionMenuTests",
            dependencies: [
                "SessionMenu",
                .product(name: "Testing", package: "swift-testing")
            ]
        ),
    ]
)
