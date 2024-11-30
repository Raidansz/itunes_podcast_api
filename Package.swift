// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ItunesPodcastManager",
    platforms: [
        .iOS(.v17) // Minimum iOS version set to iOS 17
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ItunesPodcastManager",
            targets: ["ItunesPodcastManager"]
        ),
    ],
    dependencies: [
        // External dependencies for the package
        .package(
            url: "https://github.com/SwiftyJSON/SwiftyJSON.git",
            from: "5.0.2"
        )
    ],
    targets: [
        // Define targets for each library or test module
        .target(
            name: "ItunesPodcastManager",
            dependencies: [
                .product(name: "SwiftyJSON", package: "SwiftyJSON")
            ]
        )
    ]
)

