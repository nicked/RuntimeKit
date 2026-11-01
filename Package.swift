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
    dependencies: [
		.package(url: "https://github.com/ordo-one/benchmark", .upToNextMajor(from: "1.0.0")),
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
        .executableTarget(
            name: "RuntimeKitBenchmarks",
            dependencies: [
                .product(name: "Benchmark", package: "benchmark"),
                "RuntimeKit",
            ],
            path: "Benchmarks/Benchmarks",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "benchmark")
            ]
        ),
    ]
)
