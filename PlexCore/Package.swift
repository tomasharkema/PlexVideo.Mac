// swift-tools-version: 6.3

import PackageDescription

let swiftUiDependencies: [Package.Dependency] = [
  //  .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.60.1"),
  // .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.63.2")
]

let swiftUiPlugins: [Target.PluginUsage] = [
  // .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
]

let package = Package(
  name: "PlexCore",
  platforms: [.iOS(.v26), .macOS(.v26), .macCatalyst(.v26)],
  products: [
    .library(
      name: "PlexCore",
      targets: ["PlexCore", "PlexUIKit"]
    ),
    .library(
      name: "PlexUIKit",
      targets: ["PlexUIKit"]
    ),
  ],
  dependencies: [
    //    .package(url: "https://github.com/shibapm/PackageConfig.git", from: "1.1.3"),

    .package(url: "https://github.com/tomasharkema/swift-rawjson", from: "0.0.27"),
    .package(url: "https://github.com/tomasharkema/swift-tracing", from: "0.0.43"),
    // .package(url: "https://github.com/tomasharkema/StringBuilder", branch: "main"),
    // .package(url: "https://github.com/IanKeen/MacroKit", branch: "main"),
    //    .package(url: "https://github.com/zijievv/sf-symbols-generator", from: "1.0.0"),
    //    .package(url: "https://github.com/ShenghaiWang/SwiftMacros", from: "2.0.1"),
    .package(url: "https://github.com/SwiftedMind/Processed", from: "1.0.0"),
    .package(url: "https://github.com/SwiftyLab/MetaCodable", from: "1.6.0"),
    .package(url: "https://github.com/siteline/swiftui-introspect", from: "26.0.1"),
    .package(url: "https://github.com/reddavis/Asynchrone", from: "0.21.0"),
    .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.1.3"),
    .package(url: "https://github.com/joshuawright11/papyrus", branch: "main"),
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.0.1"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.12.0"),
    .package(url: "https://github.com/pointfreeco/swift-nonempty", branch: "main"),
    .package(url: "https://github.com/krzysztofzablocki/Inject", from: "1.5.2"),

  ] + swiftUiDependencies,
  targets: [
    .target(
      name: "PlexShared",
      dependencies: [
        "MetaCodable",
        .product(name: "RawJson", package: "swift-rawjson"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "Papyrus", package: "papyrus"),
      ],
      plugins: swiftUiPlugins
    ),
    .target(
      name: "PlexApi",
      dependencies: [
        "PlexShared",
        "AsyncHelpers",
        "MetaCodable",
        "Asynchrone",
        "Processed",
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        // .product(name: "DependenciesMacros", package: "swift-dependencies"),
        .product(name: "Papyrus", package: "papyrus"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        // .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
      ],
      resources: [
        .process("PreviewResources")
      ],
    ),
    .target(
      name: "PlexCore",
      dependencies: [
        "PlexApi",
        "PlexShared",
        // "Processed",
        .product(
          name: "SwiftUIIntrospect",
          package: "swiftui-introspect",
          condition: .when(platforms: [.macOS])
        ),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        //        .product(name: "FirebaseAnalyticsWithoutAdIdSupport", package: "firebase-ios-sdk"),
        //        .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
      ],
      plugins: swiftUiPlugins
    ),
    .target(
      name: "PlexUIKit",
      dependencies: [
        "Inject",
        "PlexShared",
        "PlexApi",
        "PlexCore",
        //        .product(name: "SFSymbolsGenerator", package: "sf-symbols-generator"),
      ],
      resources: [
        .process("Resources")
      ],
      plugins: swiftUiPlugins
    ),
    .target(
      name: "AsyncHelpers",
      dependencies: [
        .product(name: "StringsBuilder", package: "swift-tracing"),
        .product(name: "SwiftStacktrace", package: "swift-tracing"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "NonEmpty", package: "swift-nonempty"),
      ],
      plugins: swiftUiPlugins
    ),
    .executableTarget(
      name: "PlexRunner",
      dependencies: [
        "PlexApi",
        "PlexCore",
      ]
    ),
  ]
)
