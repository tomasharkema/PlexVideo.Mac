//
//  ServerAndPing.swift
//
//
//  Created by Tomas Harkema on 25/10/2023.
//

import InitMacro
import PlexShared

@Init(public: true)
public struct ServerAndPings: Sendable, Equatable {
  public let server: Server
  public let pings: [PingResult]
}

extension ServerAndPings: Identifiable {
  public var id: Server.ID {
    server.id
  }
}
