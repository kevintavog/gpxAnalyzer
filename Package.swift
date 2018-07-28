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
        .package(url: "https://github.com/jakeheis/SwiftCLI", from: "5.1.2"),
// Until SwiftyJSON master is Linux compatible, use the branch waiting to be merged
// .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.x.x"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .branch("swift-test-macos")),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "4.7.3"),
    ],
    targets: [
        .target(
            name: "gpxAnalyzer",
            dependencies: ["GpxAnalyzerCore", "SwiftCLI", "SwiftyXML"]),
        .target(
            name: "GpxAnalyzerCore",
            dependencies: ["Alamofire", "SwiftyJSON", "SwiftyXML"]),
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
