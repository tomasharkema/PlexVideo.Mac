//
//  PlexCore.swift
//
//
//  Created by Tomas Harkema on 27/10/2023.
//

#if canImport(FirebaseCore)
  public import FirebaseCore
#endif
#if canImport(FirebaseCrashlytics)
  public import FirebaseCrashlytics
#endif
#if canImport(FirebaseAnalyticsWithoutAdIdSupport)
  public import FirebaseAnalyticsWithoutAdIdSupport
#endif

import Dependencies
import PlexApi

// public final class StorageContainer {
//  @Dependency(\.serverLocatorStorageProviding)
//  private var serverLocatorStorageProviding
//
//  @Dependency(\.requestorStorageProviding)
//  private var requestorStorageProviding
//
//  @Dependency(\.authStorageProviding)
//  private var authStorageProviding
//
//  init() { }
// }
//
// public final class StorageAccessor {
//
//  @Dependency(\.storage)
//  private var storage
//
//  private var storageContainer: StorageContainer?
//
//  public init() {
//    self.storageContainer = withDependencies(from: self) {
//      $0.serverLocatorStorageProviding = storage
//      $0.requestorStorageProviding = storage
//      $0.authStorageProviding = storage
//    } operation: {
//      StorageContainer()
//    }
//  }
// }
