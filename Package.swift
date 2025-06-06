// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapacitorLiveActivity",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "CapacitorLiveActivity",
            targets: ["LiveActivityPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "LiveActivityPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/LiveActivityPlugin"),
        .testTarget(
            name: "LiveActivityPluginTests",
            dependencies: ["LiveActivityPlugin"],
            path: "ios/Tests/LiveActivityPluginTests")
    ]
)
