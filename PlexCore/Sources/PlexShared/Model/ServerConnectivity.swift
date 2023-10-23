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
    self.serverID = server.id
  }
}

public struct ServerWithConnectionID: Hashable {
  let serverID: Server.ID
  let connectionID: Connection.ID

  init(
    server: Server,
    connection: Connection
  ) {
    self.serverID = server.id
    self.connectionID = connection.id
  }
}

@Codable
public struct ServerWithConnection: Sendable, Equatable, Identifiable {
  public let server: Server
  public let connection: Connection

  public init(server: Server, connection: Connection) {
    self.server = server
    self.connection = connection
  }

  public var uri: URL {
    connection.uri
  }

  public var id: ServerWithConnectionID {
    ServerWithConnectionID(
      server: server,
      connection: connection
    )
  }

  public var connections: [ServerWithConnection] {
    server.connections.map {
      ServerWithConnection(server: server, connection: $0)
    }
  }
}

@Codable
public struct ServerWithCurrentConnection: Sendable, Equatable, Identifiable {
  public let server: Server
  public let connection: Connection

  public init(server: Server, connection: Connection) {
    self.server = server
    self.connection = connection
  }

  public var uri: URL {
    connection.uri
  }

  public var id: ServerWithCurrentConnectionID {
    ServerWithCurrentConnectionID(
      server: server
    )
  }

  //  public var connections: [ServerWithCurrentConnection] {
  //    server.connections.map {
  //      ServerWithCurrentConnection(server: server, connection: $0)
  //    }
  //  }
}

public struct VideoFromServerID: Hashable {
  let videoID: Video.ID
  let serverID: ServerWithCurrentConnection.ID

  init(video: Video, server: ServerWithCurrentConnection) {
    self.videoID = video.id
    self.serverID = server.id
  }
}

@Codable
public struct VideoFromServer: Sendable, Equatable, Identifiable {
  public let video: Video
  public let server: ServerWithCurrentConnection

  public init(video: Video, server: ServerWithCurrentConnection) {
    self.video = video
    self.server = server
  }

  public var id: VideoFromServerID {
    VideoFromServerID(video: video, server: server)
  }
}
