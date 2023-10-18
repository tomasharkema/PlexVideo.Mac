//
//  UserDefaults.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import Foundation

extension UserDefaults {
  nonisolated func set<CodableType: Codable>(
    value: CodableType,
    key: String,
    _ encoder: JSONEncoder = .init()
  ) async throws {
    let data = try encoder.encode(value)
    set(data, forKey: key)
  }

  nonisolated func object<CodableType: Codable>(
    _ codableType: CodableType.Type,
    key: String,
    _ decoder: JSONDecoder = .init()
  ) async throws -> CodableType? {
    guard let data = data(forKey: key) else {
      return nil
    }

    return try decoder.decode(codableType, from: data)
  }
}
