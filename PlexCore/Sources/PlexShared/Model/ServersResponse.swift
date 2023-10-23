//
//  DevicesResponse.swift
//
//
//  Created by Tomas Harkema on 17/10/2023.
//

import Foundation
import MetaCodable

public typealias ServersResponse = [ServerAndCapabilities]

public struct ServerAndCapabilities: Sendable {
  public let server: ServerWithConnection
  public let capabilities: Result<Root<Capabilities>, any Error>

  public init(server: ServerWithConnection, capabilities: Result<Root<Capabilities>, any Error>) {
    self.server = server
    self.capabilities = capabilities
  }

  public var connections: [ServerWithConnection] {
    server.connections
  }
}

extension ServerAndCapabilities: Identifiable {
  public var id: Server.ID {
    server.server.id
  }
}

@Codable
public struct Server: Sendable, Equatable {
  public let name: String
  public let product: String
  public let productVersion: String
  public let platform: String
  public let platformVersion: String
  public let device: String
  public let provides: String
  @CodedBy(RawRepresentableCoder<ServerIdentifier>())
  public let clientIdentifier: ServerIdentifier
  public let ownerId: String?
  public let sourceTitle: String?
  public let publicAddress: String
  public let publicAddressMatches: Bool
  public let owned: Bool
  public let home: Bool
  public let synced: Bool
  public let relay: Bool
  public let presence: Bool
  public let httpsRequired: Bool
  public let createdAt: Date
  public let lastSeenAt: Date
  public let connections: [Connection]
}

extension Server: Identifiable {
  public var id: ServerIdentifier {
    clientIdentifier
  }
}

@Codable
public struct ServerIdentifier: RawRepresentable, Hashable, Sendable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

//extension Server {
//  static var preview: [Server] {
//    let decoder = JSONDecoder.default
//    decoder.dateDecodingStrategy = .formatted(.iso8601Full)
//    // swiftlint:disable:next force_try
//    return try! decoder.decode(
//      [Server].self,
//      from: Data(
//        """
//        [
//        {
//        "name": "Hera",
//        "product": "Plex Media Server",
//        "productVersion": "1.31.3.6868-28fc46b27",
//        "platform": "Linux",
//        "platformVersion": "5.19.17-Unraid (#2 SMP PREEMPT_DYNAMIC Wed Nov 2 11:54:15 PDT 2022)",
//        "device": "PC",
//        "clientIdentifier": "96f2fe7a78c9dc1f16a16bedbe90f98149be16b4",
//        "createdAt": "2022-06-02T00:54:26Z",
//        "lastSeenAt": "2023-04-11T05:53:59Z",
//        "provides": "server",
//        "ownerId": "string",
//        "sourceTitle": "string",
//        "publicAddress": "68.248.140.20",
//        "accessToken": "CR3nxzsaSHdWx_WwZsJL",
//        "owned": true,
//        "home": true,
//        "synced": true,
//        "relay": false,
//        "presence": true,
//        "httpsRequired": true,
//        "publicAddressMatches": true,
//        "dnsRebindingProtection": true,
//        "natLoopbackSupported": true,
//        "connections": [
//          {
//            "protocol": "http",
//            "address": "172.18.0.1",
//            "port": 32400,
//            "uri": "http://172.18.0.1:32400",
//            "local": true,
//            "relay": false,
//            "IPv6": false
//          },
//          {
//            "protocol": "http",
//            "address": "68.248.140.20",
//            "port": 32400,
//            "uri": "http://68.248.140.20:32400",
//            "local": false,
//            "relay": false,
//            "IPv6": false
//          }
//        ]
//        }
//        ]
//        """.utf8
//      )
//    )
//  }
//}

//extension Server {
//  public static let preview1 = Server.preview[0]

//  public static let preview2 = ServersResponse.preview[1]
//}

//extension ServerAndCapabilities {
//  public static let preview1 = ServerAndCapabilities(
//    server: .preview1,
//    capabilities: .failure(NullError())
//  )
//}
//
//public struct NullError: Error {}
