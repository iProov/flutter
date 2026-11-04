// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iproov_flutter",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .library(name: "iproov-flutter", targets: ["iproov_flutter"])
    ],
    targets: [
        .target(
            name: "iproov_flutter",
            dependencies: ["iProov"]
        ),
        // Embedded by scripts/fetch-native-sdks.sh, shared with the podspec's vendored_frameworks
        .binaryTarget(
            name: "iProov",
            path: "Frameworks/iProov.xcframework"
        )
    ]
)
