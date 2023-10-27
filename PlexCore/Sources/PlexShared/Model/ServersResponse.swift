//
//  ServersResponse.swift
//
//
//  Created by Tomas Harkema on 17/10/2023.
//

import Foundation
import MetaCodable

public typealias ServersResponse = [ServerAndCapabilities]

public struct ServerAndCapabilities: Sendable {
  public let server: Server
  public let capabilities: Result<Root<Capabilities>, any Error>

  package init(server: Server, capabilities: Result<Root<Capabilities>, any Error>) {
    self.server = server
    self.capabilities = capabilities
  }

  public var connections: [ServerWithConnection] {
    server.connections.map {
      .init(server: server, connection: $0)
    }
  }
}

extension ServerAndCapabilities: Identifiable {
  public var id: Server.ID {
    server.id
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
  public let clientIdentifier: String
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
  public struct ID: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }

  public var id: ID {
    ID(rawValue: clientIdentifier)
  }
}
