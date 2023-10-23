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
  public var id: String {
    uri.absoluteString
  }
}

extension Connection {
  //  public static let preview1 = Connection(
  //    protocol: "https",
  //    address: "1.2.3.4",
  //    port: 8080,
  //    uri: URL(string: "https://1.2.3.4")!,
  //    local: true,
  //    relay: false,
  //    IPv6: false
  //  )
  //
  //  public static let preview2 = Connection(
  //    protocol: "https",
  //    address: "5.6.7.8",
  //    port: 8080,
  //    uri: URL(string: "https://5.6.7.8")!,
  //    local: false,
  //    relay: false,
  //    IPv6: false
  //  )

  //  public static let preview3 = Server.preview1.connections[0]
}
