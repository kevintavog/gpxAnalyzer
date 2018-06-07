// swift-tools-version:4.1

import PackageDescription

let package = Package(
    name: "gpxAnalyzer",
    products: [
        .executable(name: "gpxAnalyzer", targets: ["gpxAnalyzer"]),
        .library(name: "GpxAnalyzerCore", targets: ["GpxAnalyzerCore"])
    ],
    dependencies: [
         .package(url: "https://github.com/chenyunguiMilook/SwiftyXML.git", from: "1.6.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "gpxAnalyzer",
            dependencies: ["GpxAnalyzerCore","SwiftyXML"]),
        .target(
            name: "GpxAnalyzerCore",
            dependencies: ["SwiftyXML"]),
        .testTarget(
            name: "gpxAnalyzerTests",
            dependencies: ["GpxAnalyzerCore"]),
    ]
)
