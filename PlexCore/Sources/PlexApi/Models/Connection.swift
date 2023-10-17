//
//  Connection.swift
//  
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation

public struct Connection: Codable, Equatable, Sendable {
  public let `protocol`: String
  public let address: String
  public let port: Int
  public let uri: String
  public let local: Bool
  public let relay: Bool
  public let IPv6: Bool
}
