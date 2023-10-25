//
//  User.swift
//
//
//  Created by Tomas Harkema on 24/10/2023.
//

import Foundation
import MetaCodable

@Codable
public struct User: Hashable, Equatable {
  @CodedAt("id")
  public let rawId: String
  public let thumb: URL?
  public let title: String
}

extension User: Identifiable {
  public struct ID: RawRepresentable, Hashable, Codable {
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }

  public var id: ID {
    ID(rawValue: rawId)
  }
}
