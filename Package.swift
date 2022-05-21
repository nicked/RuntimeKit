// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "RuntimeKit",
    platforms: [.iOS(.v13), .macOS(.v13)],
    products: [
        .library(
            name: "RuntimeKit",
            targets: ["RuntimeKit"]
        ),
    ],
    targets: [
        .target(
            name: "RuntimeKit",
            dependencies: ["RuntimeFix"]
        ),

        .target(
            name: "RuntimeFix"
        ),

        .testTarget(
            name: "RuntimeKitTests",
            dependencies: ["RuntimeKit"]
        ),
    ]
)
