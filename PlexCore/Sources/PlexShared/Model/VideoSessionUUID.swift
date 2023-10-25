//
//  VideoSessionUUID.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation

public struct VideoSessionUUID: RawRepresentable, Sendable, Codable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}
