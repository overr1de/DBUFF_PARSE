// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DotabuffParser",
    platforms: [
        .iOS(.v15),
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "DotabuffParser",
            targets: ["DotabuffParser"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
    ],
    targets: [
        .target(
            name: "DotabuffParserCore",
            dependencies: ["SwiftSoup"],
            path: "Sources"
        ),
        .executableTarget(
            name: "DotabuffParser",
            dependencies: ["DotabuffParserCore"],
            path: ".",
            exclude: ["Tests/", "TestRunner.swift", "Sources/"],
            sources: ["DotabuffParserApp.swift"]
        ),
        .testTarget(
            name: "DotabuffParserTests",
            dependencies: ["DotabuffParserCore"],
            path: "Tests/DotabuffParserTests"
        )
    ]
)
