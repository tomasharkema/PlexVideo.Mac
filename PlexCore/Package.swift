// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("ConciseMagicFile"),
  .enableUpcomingFeature("BareSlashRegexLiterals"),
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("DisableOutwardActorInference"),
  .enableUpcomingFeature("ForwardTrailingClosures"),
  .enableExperimentalFeature("AccessLevelOnImport"),
  .enableUpcomingFeature("InternalImportsByDefault"),
  .enableExperimentalFeature("NestedProtocols"),

  .unsafeFlags(
    [
      "-Xfrontend",
      "-warn-concurrency",
      "-Xfrontend",
      "-enable-actor-data-race-checks",
      "-Xlinker",
      "-interposable",
    ],
    .when(configuration: .debug)
  ),
]

#if !os(Linux)
  let swiftUiDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/realm/SwiftLint", from: "0.53.0"),
  ]

  let swiftUiPlugins: [Target.PluginUsage] = [
    .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
  ]
#else
  let swiftUiDependencies: [Package.Dependency] = []
  let swiftUiPlugins: [Target.PluginUsage] = []
#endif

let package = Package(
  name: "PlexCore",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(
      name: "PlexCore",
      targets: ["PlexCore"]
    ),
    .library(
      name: "PlexUIKit",
      targets: ["PlexUIKit"]
    ),
    .library(
      name: "PlexCoreDynamic",
      type: .dynamic,
      targets: ["PlexCore", "PlexUIKit"]
    ),
    .executable(name: "Tester", targets: ["Tester"]),
  ],
  dependencies: [
    //    .package(path: "../../../Injected"),
    .package(url: "https://github.com/IanKeen/MacroKit", branch: "main"),
    .package(url: "https://github.com/zijievv/sf-symbols-generator", from: "1.0.0"),
    .package(url: "https://github.com/Wouter01/SwiftUI-Macros", from: "1.0.0"),
    .package(url: "https://github.com/tomasharkema/SwiftMacros.git", branch: "main"),
    .package(url: "https://github.com/SwiftedMind/Processed", from: "1.0.0"),
    .package(url: "https://github.com/tomasharkema/MetaCodable", branch: "main"),
    .package(url: "https://github.com/siteline/swiftui-introspect", from: "1.0.0"),
    .package(url: "https://github.com/reddavis/Asynchrone", from: "0.21.0"),
    .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
    .package(url: "https://github.com/tomasharkema/swift-rawjson", from: "0.0.26"),
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.16.0"),
    .package(url: "https://github.com/joshuawright11/papyrus", from: "0.5.2"),
    .package(url: "https://github.com/krzysztofzablocki/Inject.git", from: "1.0.5"),
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.0.1"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
    .package(url: "https://github.com/tgrapperon/swift-dependencies-additions", from: "1.0.0"),

  ] + swiftUiDependencies,
  targets: [
    .target(
      name: "PlexShared",
      dependencies: [
        "Inject",

        "MetaCodable",

        .product(name: "RawJson", package: "swift-rawjson"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
//        .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
//        .product(name: "Papyrus", package: "papyrus"),
      ],
      swiftSettings: swiftSettings,
      plugins: swiftUiPlugins
    ),
    .target(
      name: "PlexApi",
      dependencies: [
        "PlexShared",
        "AsyncHelpers",
        "MetaCodable",
        "Asynchrone",
        "SwiftMacros",
        "Inject",

        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
//        .product(name: "Papyrus", package: "papyrus"),
        .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
      ],
      resources: [
        .process("PreviewResources"),
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

        .product(name: "SwiftUIMacros", package: "SwiftUI-Macros"),
        .product(
          name: "SwiftUIIntrospect",
          package: "swiftui-introspect",
          condition: .when(platforms: [.macOS])
        ),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
        .product(name: "FirebaseAnalyticsWithoutAdIdSupport", package: "firebase-ios-sdk"),
        .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
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
        "Inject",

        .product(name: "SwiftUIMacros", package: "SwiftUI-Macros"),
        .product(name: "SFSymbolsGenerator", package: "sf-symbols-generator"),
      ],
      resources: [
        .process("Resources"),
      ],
      swiftSettings: swiftSettings,
      plugins: swiftUiPlugins
    ),
    .target(
      name: "AsyncHelpers",
      dependencies: [
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
      ],
      swiftSettings: swiftSettings,
      plugins: swiftUiPlugins
    ),
    .executableTarget(
      name: "Tester",
      dependencies: ["PlexCore"]
    ),
  ]
)
