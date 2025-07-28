// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "BetApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "BetApp",
            targets: ["BetApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "1.0.0"),
        .package(url: "https://github.com/stripe/stripe-ios.git", from: "23.0.0"),
    ],
    targets: [
        .target(
            name: "BetApp",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "StripePaymentSheet", package: "stripe-ios"),
            ]),
        .testTarget(
            name: "BetAppTests",
            dependencies: ["BetApp"]),
    ]
)