// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "RuntimeKitBenchmarks",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/ordo-one/benchmark", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .executableTarget(
            name: "RuntimeKitBenchmarks",
            dependencies: [
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "RuntimeKit", package: "RuntimeKit"),
            ],
            path: "Benchmarks",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "benchmark")
            ]
        ),
    ]
)
