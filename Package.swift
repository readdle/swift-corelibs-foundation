// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Foundation",
    products: [],
    dependencies: [],
    targets: [
        .testTarget(
            name: "TestFoundation",
            path: "TestFoundation",
            exclude: [
                "main.swift",
                "xdgTestHelper/main.swift",
                "TestProcess.swift",
                "TestNSProgressFraction.swift",
                "TestFileManager.swift"
            ])
    ]
)
