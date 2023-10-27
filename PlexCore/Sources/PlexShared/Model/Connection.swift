//
//  Connection.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation
import MetaCodable

@Codable
public struct Connection: Equatable, Sendable, Hashable {
  public let `protocol`: String
  public let address: String
  public let port: Int
  public let uri: URL
  public let local: Bool
  public let relay: Bool
  public let IPv6: Bool
}

extension Connection: Identifiable {
  public struct ID: RawRepresentable, Codable, Hashable {
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }

  public var id: ID {
    ID(rawValue: uri.absoluteString)
  }
}
