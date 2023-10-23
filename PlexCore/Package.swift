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
  .unsafeFlags(
    [
      "-warn-concurrency",
      "-Xfrontend",
      "-debug-time-function-bodies",
      "-Xfrontend",
      "-warn-long-function-bodies=50",
      "-Xfrontend",
      "-warn-long-expression-type-checking=50",
    ],
    .when(configuration: .debug)
  ),
]

let swiftUiDependencies: [Package.Dependency] = [
  .package(url: "https://github.com/realm/SwiftLint", from: "0.53.0"),
  .package(url: "https://github.com/apple/swift-format", from: "509.0.0"),
]

let swiftUiPlugins: [Target.PluginUsage] = [
  //  .plugin(name: "SwiftLintPlugin", package: "SwiftLint")
]

let package = Package(
  name: "PlexCore",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(
      name: "PlexCore",
      targets: ["PlexCore"]
    ),
    .library(name: "PlexUIKit", targets: ["PlexUIKit"]),
  ],
  dependencies: [
    .package(path: "../../../Inject"),

    .package(url: "https://github.com/LeonardoCardoso/InitMacro", branch: "main"),
    .package(url: "https://github.com/SwiftedMind/Processed", from: "1.0.0"),
    .package(url: "https://github.com/tomasharkema/SwiftMacros", branch: "main"),
    .package(url: "https://github.com/tomasharkema/MetaCodable", from: "0.0.1"),
    //    .package(url: "https://github.com/SwiftyLab/MetaCodable", from: "1.0.0"),

    .package(url: "https://github.com/siteline/swiftui-introspect", from: "1.0.0"),
    .package(url: "https://github.com/reddavis/Asynchrone", from: "0.21.0"),

  ] + swiftUiDependencies,
  targets: [
    .target(
      name: "PlexShared",
      dependencies: [
        "Inject",

        "InitMacro",
        "MetaCodable",
      ],
      swiftSettings: swiftSettings,
      plugins: swiftUiPlugins
    ),
    .target(
      name: "PlexApi",
      dependencies: [
        "PlexShared",
        "AsyncHelpers",
        "Inject",
        "MetaCodable",
        "Asynchrone",
        "SwiftMacros",
      ],
      swiftSettings: swiftSettings,
      plugins: swiftUiPlugins
    ),
    .target(
      name: "PlexCore",
      dependencies: [
        "PlexApi",
        "PlexShared",

        "Inject",
        "Processed",

        .product(name: "SwiftUIIntrospect", package: "swiftui-introspect"),
      ],
      swiftSettings: swiftSettings,
      plugins: swiftUiPlugins
    ),
    .target(
      name: "PlexUIKit",
      dependencies: [
        "PlexShared",
        "PlexApi",
        "PlexCore",
      ],
      resources: [
        .process("Resources")
      ],
      swiftSettings: swiftSettings,
      plugins: swiftUiPlugins
    ),
    .target(
      name: "AsyncHelpers",
      swiftSettings: swiftSettings,
      plugins: swiftUiPlugins
    ),
    //      .testTarget(
    //          name: "PlexCoreTests",
    //          dependencies: ["PlexCore"]
    //      ),
  ]
)
