//
//  ServerAndPing.swift
//
//
//  Created by Tomas Harkema on 25/10/2023.
//

import PlexShared

public struct ServerAndPings: Sendable, Equatable {
  public let server: Server
  public let pings: [PingResult]

  package init(server: Server, pings: [PingResult]) {
    self.server = server
    self.pings = pings
  }
}

extension ServerAndPings: Identifiable {
  public var id: Server.ID {
    server.id
  }
}
