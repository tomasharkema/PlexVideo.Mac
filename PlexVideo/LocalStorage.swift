//
//  LocalStorage.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import Foundation
import SwiftUI

struct Storage {
  @AppStorage("plexToken")
  static var plexToken: String?

  static var uuid: String {
    let saved = UserDefaults.standard.string(forKey: "uuid")
    if let saved = saved {
      return saved
    }

    let generated = UUID().uuidString
    UserDefaults.standard.set(generated, forKey: "uuid")
    return generated
  }

  static func setLastPlayed(lastPlayed: Video?) async throws {
    try await UserDefaults.standard.set(lastPlayed, key: "lastPlayed")
  }

  static func getLastPlayed() async throws -> Video? {
    return try await UserDefaults.standard.object(Video.self, key: "lastPlayed")
  }

  static func setSavedOffset(progress: Progress?, video: Video) async throws {
    try await UserDefaults.standard.set(progress, key: "PROGRESS_NEW_\(video.key)")
  }

  static func getSavedOffset(video: Video) async throws -> Progress? {
    return try await UserDefaults.standard.object(Progress.self, key: "PROGRESS_NEW_\(video.key)")
  }
}
