//
//  RatingKey.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation

public struct RatingKey: RawRepresentable, Codable, Equatable, Sendable {
  public var rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}
