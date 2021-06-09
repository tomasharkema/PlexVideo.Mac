//
//  LocalStorage.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import Foundation
import SwiftUI

@MainActor
class Storage: ObservableObject {
  static let shared = Storage()

  @AppStorage("plexTokenV2")
  var plexToken: String?

  @AppStorage("lastUsedLocalHost")
  var lastUsedLocalHost: String?

  @AppStorage("lastUsedRemoteHost")
  var lastUsedRemoteHost: String?

  var uuid: String {
    let saved = UserDefaults.standard.string(forKey: "uuid")
    if let saved = saved {
      return saved.lowercased()
    }

    let generated = UUID().uuidString.lowercased()
    UserDefaults.standard.set(generated, forKey: "uuid")
    return generated
  }

  func setLastPlayed(lastPlayed: Video?) async throws {
    try await UserDefaults.standard.set(lastPlayed, key: "lastPlayed")
  }

  func getLastPlayed() async throws -> Video? {
    return try await UserDefaults.standard.object(Video.self, key: "lastPlayed")
  }

  func setSavedOffset(progress: Progress?, video: Video) async throws {
    try await UserDefaults.standard.set(progress, key: "PROGRESS_NEW_\(video.key.rawValue)")
  }

  func getSavedOffset(video: Video) async throws -> Progress? {
    return try await UserDefaults.standard.object(
      Progress.self,
      key: "PROGRESS_NEW_\(video.key.rawValue)"
    )
  }

  func getToken() -> String? {
    return plexToken
  }

  func getUUID() -> String? {
    return uuid
  }
}
