//
//  ServerConnectivity.swift
//
//
//  Created by Tomas Harkema on 23/10/2023.
//

import Foundation
import MetaCodable

public struct ServerWithCurrentConnectionID: Hashable {
  let serverID: Server.ID

  init(
    server: Server
  ) {
    serverID = server.id
  }
}

public struct ServerWithConnectionID: Hashable {
  let serverID: Server.ID
  let connectionID: Connection.ID

  init(
    server: Server,
    connection: Connection
  ) {
    serverID = server.id
    connectionID = connection.id
  }
}

@Codable
public struct ServerWithConnection: Sendable, Equatable {
  public let server: Server
  public let connection: Connection

  public init(server: Server, connection: Connection) {
    self.server = server
    self.connection = connection
  }

  public var uri: URL {
    connection.uri
  }

  public var connections: [ServerWithConnection] {
    server.connections.map {
      ServerWithConnection(server: server, connection: $0)
    }
  }
}

extension ServerWithConnection: Identifiable {
  public struct ID: Hashable {
    public let serverID: Server.ID
    public let connectionID: Connection.ID

    public init(server: Server, connection: Connection) {
      serverID = server.id
      connectionID = connection.id
    }
  }

  public var id: ID {
    ID(server: server, connection: connection)
  }
}

@Codable
public struct ServerWithCurrentConnection: Sendable, Equatable, Codable {
  public let server: Server
  public let connection: Connection

  public init(server: Server, connection: Connection) {
    self.server = server
    self.connection = connection
  }

  public var uri: URL {
    connection.uri
  }
}

extension ServerWithCurrentConnection: Identifiable {
  public struct ID: Hashable {
    public let serverID: Server.ID

    public init(server: Server) {
      serverID = server.id
    }
  }

  public var id: ID {
    ID(server: server)
  }
}

@Codable
public struct VideoFromServer: Sendable, Equatable {
  public let video: Video
  public let server: ServerWithCurrentConnection

  public init(video: Video, server: ServerWithCurrentConnection) {
    self.video = video
    self.server = server
  }
}

extension VideoFromServer: Identifiable {
  public struct ID: Hashable {
    let videoID: Video.ID
    let serverID: ServerWithCurrentConnection.ID

    init(video: Video, server: ServerWithCurrentConnection) {
      videoID = video.id
      serverID = server.id
    }
  }

  public var id: ID {
    ID(video: video, server: server)
  }
}
