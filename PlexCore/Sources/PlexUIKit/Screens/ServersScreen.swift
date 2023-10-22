//
//  ServersScreen.swift
//
//
//  Created by Tomas Harkema on 20/10/2023.
//

import PlexApi
import PlexShared
import SwiftUI

public struct ServersScreen: View {
  private let servers: [Server]
  private let currentConnection: Connection?
  private let pings: [Connection: PingResult]

  public init(
    servers: [Server],
    currentConnection: Connection?,
    pings: [Connection: PingResult]
  ) {
    self.servers = servers
    self.currentConnection = currentConnection
    self.pings = pings
  }

  public var body: some View {
    ScrollView {
      VStack {
        ForEach(servers) { server in
          DeviceView(
            server: server,
            currentConnection: currentConnection,
            pings: pings
          )
        }
      }
      .padding()
    }
  }
}

#Preview {
  ServersScreen(
    servers: [
      .preview1,
      .preview2,
    ],
    currentConnection: .preview1,
    pings: [:]
  )
  .background(Color.black)
  .preferredColorScheme(.dark)
}
