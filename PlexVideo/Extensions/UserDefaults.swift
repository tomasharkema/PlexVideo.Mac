//
//  UserDefaults.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import Foundation

extension UserDefaults {
  func set<C: Codable>(_ c: C, key: String) async throws {
    let data = try await Coders().encode(c)
    set(data, forKey: key)
  }

  func object<C: Codable>(_ c: C.Type, key: String) async throws -> C? {
    guard let data = data(forKey: key) else {
      return nil
    }

    return try await Coders().decode(c, from: data)
  }
}

actor Coders {
  func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    return try JSONDecoder().decode(type, from: data)
  }

  func encode<T: Encodable>(_ value: T) throws -> Data {
    return try JSONEncoder().encode(value)
  }
}
