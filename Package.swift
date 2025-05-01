// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MultiPicker",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MultiPicker",
            targets: ["MultiPicker"]),
    ],
    dependencies: [
        .package(url: "https://github.com/toastersocks/Helpers.git", from: "0.0.0"),
        .package(url: "https://github.com/toastersocks/Flow.git", from: "1.2.3"),
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MultiPicker",
            dependencies: ["Helpers", "Flow"]),
        .testTarget(
            name: "MultiPickerTests",
            dependencies: ["MultiPicker"]),
    ]
)
