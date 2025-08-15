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
        .executableTarget(
            name: "DotabuffParser",
            dependencies: ["SwiftSoup"],
            path: ".",
            exclude: ["Tests/", "TestRunner.swift"]
        ),
        .testTarget(
            name: "DotabuffParserTests",
            dependencies: ["DotabuffParser"],
            path: "Tests/DotabuffParserTests"
        )
    ]
)
