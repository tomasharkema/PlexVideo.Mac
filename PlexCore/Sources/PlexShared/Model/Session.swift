//
//  Session.swift
//
//
//  Created by Tomas Harkema on 24/10/2023.
//

import Foundation
import MetaCodable

@Codable
public struct Session: Hashable, Equatable {
  @CodedAt("id")
  public let rawId: String
  public let bandwidth: Double
  public let location: String
}

extension Session: Identifiable {
  public struct ID: RawRepresentable, Hashable {
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }

  public var id: ID {
    ID(rawValue: rawId)
  }
}
