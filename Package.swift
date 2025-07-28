// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "BetApp",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "BetApp",
            targets: ["BetApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "BetApp",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ]),
        .testTarget(
            name: "BetAppTests",
            dependencies: ["BetApp"]),
    ]
)