// swift-tools-version:4.1

import PackageDescription

let package = Package(
    name: "gpxAnalyzer",
    products: [
        .executable(name: "gpxAnalyzer", targets: ["gpxAnalyzer"]),
        .executable(name: "gpxFilter", targets: ["gpxFilter"]),
        .library(name: "GpxAnalyzerCore", targets: ["GpxAnalyzerCore"]),
        .library(name: "GpxFilterCore", targets: ["GpxFilterCore"]),
    ],
    dependencies: [
         .package(url: "https://github.com/chenyunguiMilook/SwiftyXML.git", from: "1.6.0"),
         .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.2.1"),
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
        .target(
            name: "gpxFilter",
            dependencies: ["GpxAnalyzerCore", "GpxFilterCore", "SwiftyXML", "Utility"]),
        .target(
            name: "GpxFilterCore",
            dependencies: ["SwiftyXML", "Utility"]),
    ]
)
