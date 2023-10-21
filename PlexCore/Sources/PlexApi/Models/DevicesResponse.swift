//
//  Devicesesponse.swift
//
//
//  Created by Tomas Harkema on 17/10/2023.
//

import Foundation
import MetaCodable

public typealias ServersResponse = [Server]


//Array [
//  name string
//  product string
//  productVersion string
//  platform string
//  platformVersion string
//  device string
//  clientIdentifier string
//  createdAt date-time
//  lastSeenAt date-time
//  provides string
//  ownerId nullable
//  sourceTitle nullable
//  publicAddress string
//  accessToken string
//  owned boolean
//  home boolean
//  synced boolean
//  relay boolean
//  presence boolean
//  httpsRequired boolean
//  publicAddressMatches boolean
//  dnsRebindingProtection boolean
//  natLoopbackSupported boolean
//  connections object[]
//  ]

@Codable
public struct Server: Sendable, Hashable {
  public let name: String
  public let product: String
  public let platformVersion: String
  public let device: String
  public let provides: String
  public let clientIdentifier: String
  public let ownerId: String?
  public let sourceTitle: String?
  public let publicAddress: String
  public let publicAddressMatches: Bool
  public let connections: [Connection]

  fileprivate init(
    name: String, product: String, platformVersion: String, device: String, provides: String,
    clientIdentifier: String, ownerId: String?, sourceTitle: String?, publicAddress: String,
    publicAddressMatches: Bool, connections: [Connection]
  ) {
    self.name = name
    self.product = product
    self.platformVersion = platformVersion
    self.device = device
    self.provides = provides
    self.clientIdentifier = clientIdentifier
    self.ownerId = ownerId
    self.sourceTitle = sourceTitle
    self.publicAddress = publicAddress
    self.publicAddressMatches = publicAddressMatches
    self.connections = connections
  }
}

extension Server: Identifiable {
  public var id: Int {
    hashValue
  }
}

extension ServersResponse {
  static var preview: ServersResponse {
    // swiftlint:disable:next force_try
    try! JSONDecoder().decode(ServersResponse.self, from: Data("""
    [
    {
    "name": "Hera",
    "product": "Plex Media Server",
    "productVersion": "1.31.3.6868-28fc46b27",
    "platform": "Linux",
    "platformVersion": "5.19.17-Unraid (#2 SMP PREEMPT_DYNAMIC Wed Nov 2 11:54:15 PDT 2022)",
    "device": "PC",
    "clientIdentifier": "96f2fe7a78c9dc1f16a16bedbe90f98149be16b4",
    "createdAt": "2022-06-02T00:54:26.000Z",
    "lastSeenAt": "2023-04-11T05:53:59.000Z",
    "provides": "server",
    "ownerId": "string",
    "sourceTitle": "string",
    "publicAddress": "68.248.140.20",
    "accessToken": "CR3nxzsaSHdWx_WwZsJL",
    "owned": true,
    "home": true,
    "synced": true,
    "relay": true,
    "presence": true,
    "httpsRequired": true,
    "publicAddressMatches": true,
    "dnsRebindingProtection": true,
    "natLoopbackSupported": true,
    "connections": [
      {
        "protocol": "http",
        "address": "172.18.0.1",
        "port": 32400,
        "uri": "http://172.18.0.1:32400",
        "local": true,
        "relay": true,
        "IPv6": true
      }
    ]
    }
    ]
    """.utf8))
  }
}

extension Server {
  public static let preview1 = ServersResponse.preview[0]

  public static let preview2 = ServersResponse.preview[1]
}
