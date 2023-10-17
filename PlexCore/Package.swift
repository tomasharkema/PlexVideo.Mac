// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PlexCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PlexCore",
            targets: ["PlexCore"]
        ),
    ],
    dependencies: [
      .package(path: "../../../AsyncAwaitHelpers"),
      .package(path: "../../../Inject"),

      .package(url: "https://github.com/LeonardoCardoso/InitMacro", branch: "main"),
      .package(url: "https://github.com/SwiftedMind/Processed", from: "1.0.0"),
      .package(url: "https://github.com/lorenzofiamingo/swiftui-cached-async-image", from: "2.1.1"),
//      .package(url: "https://github.com/MaxDesiatov/XMLCoder", from: "0.17.0"),
    ],
    targets: [
      .target(
        name: "PlexShared",
        dependencies: [
          "Inject",

          "InitMacro",
        ]
      ),
      .target(
        name: "PlexApi",
        dependencies: [
          "PlexShared",

//          "AsyncAwaitHelpers",
          "Inject",
//          "XMLCoder",
        ]
      ),
      .target(
        name: "PlexCore",
        dependencies: [
          "PlexApi",
          "PlexShared",

          "AsyncAwaitHelpers",
          "Inject",
          "Processed",
//          "XMLCoder",

          .product(name: "CachedAsyncImage", package: "swiftui-cached-async-image"),
        ]
      ),
//      .testTarget(
//          name: "PlexCoreTests",
//          dependencies: ["PlexCore"]
//      ),
    ]
)
