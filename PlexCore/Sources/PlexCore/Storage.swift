//
//  Storage.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Dependencies
import Foundation
import OSLog
import PlexApi
import PlexShared
import SwiftUI

@MainActor
public final class Storage: ObservableObject, ServerLocatorStorageProviding,
  RequestorStorageProviding, AuthStorageProviding
{
  fileprivate static let logger = Logger(subsystem: "PlexVideo", category: "Auth")

  @AppStorage("plexTokenV2")
  public var plexToken: String?

  @AppStorage("lastUsedLocalConnection")
  public var lastUsedLocalConnection: CodableWrapper<ServerWithCurrentConnection>?

  @AppStorage("lastUsedRemoteConnection")
  public var lastUsedRemoteConnection: CodableWrapper<ServerWithCurrentConnection>?

  @AppStorage("lastUsedConnection")
  public var lastUsedConnection: CodableWrapper<ServerWithCurrentConnection>?

  @AppStorage("serversResponse")
  public var servers: CodableWrapper<[Server]>?

  public nonisolated init() {}

  public var uuid: String {
    let saved = UserDefaults.standard.string(forKey: "uuid")
    if let saved {
      return saved.lowercased()
    }

    let generated = UUID().uuidString.lowercased()
    UserDefaults.standard.set(generated, forKey: "uuid")
    return generated
  }

  public func setLastPlayed(lastPlayed: VideoFromServer?) async throws {
    try await UserDefaults.standard.set(value: lastPlayed, key: "lastPlayed")
  }

  public func getLastPlayed() async throws -> Video? {
    try await UserDefaults.standard.object(Video.self, key: "lastPlayed")
  }

  public func setSavedOffset(progress: PlexShared.Progress?, video: Video) async throws {
    try await UserDefaults.standard.set(value: progress, key: "PROGRESS_\(video.key.rawValue)")
  }

  public nonisolated func getSavedOffset(video: Video) async throws -> PlexShared.Progress? {
    try await UserDefaults.standard.object(
      PlexShared.Progress.self,
      key: "PROGRESS_\(video.key.rawValue)"
    )
  }

  public func getToken() -> String? {
    plexToken
  }

  public func logout() {
    let defaults = UserDefaults.standard
    let dictionary = defaults.dictionaryRepresentation()
    dictionary.keys.forEach { key in
      defaults.removeObject(forKey: key)
    }
    plexToken = nil

    URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
  }
}

public extension DependencyValues {
  var storage: Storage {
    get { self[StorageKey.self] }
    set { self[StorageKey.self] = newValue }
  }
}

public struct StorageKey: DependencyKey {
  public static let liveValue: Storage = .init()
}

extension ServerLocatorStorageProvidingKey: DependencyKey {
  public static let liveValue: (any ServerLocatorStorageProviding) = StorageKey.liveValue
}

extension AuthStorageProvidingKey: DependencyKey {
  public static let liveValue: (any AuthStorageProviding) = StorageKey.liveValue
}

extension RequestorStorageProvidingKey: DependencyKey {
  public static let liveValue: (any RequestorStorageProviding) = StorageKey.liveValue
}

// extension ServerWithCurrentConnection: RawRepresentable {
//  public init?(rawValue: String) {
//    guard let data = rawValue.data(using: .utf8) else {
//      return nil
//    }
//
//    do {
//      self = try JSONDecoder.default.decode(ServerWithCurrentConnection.self, from: data)
//    } catch {
//      Storage.logger.error("Connection raw decode error: \(error)")
//      return nil
//    }
//  }
//
//  public var rawValue: String {
//    do {
//      let data = try JSONEncoder().encode(self)
//      return String(data: data, encoding: .utf8) ?? ""
//    } catch {
//      Storage.logger.error("Connection raw encode error: \(error)")
//      return ""
//    }
//  }
// }
