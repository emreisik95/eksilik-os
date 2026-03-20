// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EksilikApp",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "EksilikApp", targets: ["EksilikApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/tid-kijyun/Kanna.git", from: "5.3.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "EksilikApp",
            dependencies: ["Kanna", "KeychainAccess"],
            path: "."
        ),
    ]
)
