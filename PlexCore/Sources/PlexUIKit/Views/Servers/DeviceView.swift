//
//  DeviceView.swift
//
//
//  Created by Tomas Harkema on 20/10/2023.
//

import SwiftUI
import PlexApi
import PlexShared

struct DeviceView: View {
  private let server: Server
  private let currentConnection: Connection?
  private let pings: [Connection: PingResult]

  init(server: Server, currentConnection: Connection?, pings: [Connection: PingResult]) {
    self.server = server
    self.currentConnection = currentConnection
    self.pings = pings
  }

  var body: some View {
    VStack {
      HStack {
        Text(server.name).bold()

        Spacer()

        Text("public: \(server.publicAddress)")
          .monospaced()
      }

      Divider()

      ConnectionsView(connections: server.connections, currentConnection: currentConnection, pings: pings)
    }
    .padding()
    .background(Color(.plexTint).opacity(0.6))
    .cornerRadius(10)
  }
}
