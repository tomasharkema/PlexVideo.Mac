//
//  NumberLike.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation

public struct DoubleLikeError: Error {}

public struct NumberLike: Codable, Equatable, Sendable {
  public let value: Double

  public init(value: Double) {
    self.value = value
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let value = try? container.decode(Double.self) {
      self.value = value
      return
    } else if let value = try? container.decode(Int.self) {
      self.value = Double(value)
      return
    } else if let value = try? container.decode(String.self), let value = Double(value) {
      self.value = value
      return
    } else if let value = try? container.decode(Bool.self) {
      self.value = value ? 1 : 0
      return
    }

    throw DoubleLikeError()
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }
}

public extension Double {
  var doubleLike: NumberLike {
    NumberLike(value: self)
  }
}
