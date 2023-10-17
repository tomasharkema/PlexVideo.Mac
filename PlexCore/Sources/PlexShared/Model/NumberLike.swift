//
//  NumberLike.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation

public struct DoubleLikeError: Error {}

public struct NumberLike: Codable, Equatable {
  public let value: Double

  public init(value: Double) {
    self.value = value
  }

  public init(from decoder: Decoder) throws {
    let s = try decoder.singleValueContainer()

    if let v = try? s.decode(Double.self) {
      value = v
      return
    } else if let v = try? s.decode(Int.self) {
      value = Double(v)
      return
    } else if let v = try? s.decode(String.self), let value = Double(v) {
      self.value = value
      return
    } else if let v = try? s.decode(Bool.self) {
      value = v ? 1 : 0
      return
    }

    throw DoubleLikeError()
  }

  public func encode(to encoder: Encoder) throws {
    var s = encoder.singleValueContainer()
    try s.encode(value)
  }
}

public extension Double {
  var doubleLike: NumberLike {
    NumberLike(value: self)
  }
}
