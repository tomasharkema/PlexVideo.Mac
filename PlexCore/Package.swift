// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("ConciseMagicFile"),
  .enableUpcomingFeature("BareSlashRegexLiterals"),
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("DisableOutwardActorInference"),
  .enableExperimentalFeature("AccessLevelOnImport"),
  .enableExperimentalFeature("VariadicGenerics"),
  .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug)),
]

// .package(url: "https://github.com/ShenghaiWang/SwiftMacros", from: "1.2.0"),
// .package(url: "https://github.com/securevale/swift-confidential", from: "0.3.0"),
// .package(url: "https://github.com/securevale/swift-confidential-plugin", from: "0.3.0"),

let swiftUiDependency: [Package.Dependency] = [
  .package(url: "https://github.com/realm/SwiftLint", from: "0.53.0"),
]

let swiftUiPlugin: [Target.PluginUsage] = [
  .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
]

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
      .package(url: "https://github.com/tomasharkema/MetaCodable", from: "0.0.1"),
      //    .package(url: "https://github.com/SwiftyLab/MetaCodable", from: "1.0.0"),

//      .package(url: "https://github.com/MaxDesiatov/XMLCoder", from: "0.17.0"),
    ] + swiftUiDependency,
    targets: [
      .target(
        name: "PlexShared",
        dependencies: [
          "Inject",

          "InitMacro",
          "MetaCodable",
        ],
        swiftSettings: swiftSettings,
        plugins: swiftUiPlugin
      ),
      .target(
        name: "PlexApi",
        dependencies: [
          "PlexShared",

//          "AsyncAwaitHelpers",
          "Inject",
//          "XMLCoder",
          "MetaCodable",
        ],
        swiftSettings: swiftSettings,
        plugins: swiftUiPlugin
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
        ],
        swiftSettings: swiftSettings,
        plugins: swiftUiPlugin
      ),
//      .testTarget(
//          name: "PlexCoreTests",
//          dependencies: ["PlexCore"]
//      ),
    ]
)
