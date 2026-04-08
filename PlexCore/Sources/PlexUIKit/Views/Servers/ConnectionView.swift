//
//  ConnectionView.swift
//
//
//  Created by Tomas Harkema on 20/10/2023.
//

@_exported import Inject
import PlexApi
import PlexCore
import PlexShared
import SwiftUI

struct ConnectionsView: View {
  @ObserveInjection private var inject

  private let connections: ServerAndPings

  init(connections: ServerAndPings) {
    self.connections = connections
  }

  var body: some View {
    ForEach(connections.pings) { server in
      ConnectionView(
        server: server.serverWithConnection,
        ping: server
      )
    }
    .enableInjection()
  }
}

@MainActor
struct ConnectionView: View {
  @ObserveInjection private var inject

  @Environment(\.serversViewModel) // ServersViewModel.self)
  private var viewModel

  private let server: ServerWithConnection
  private let ping: PingResult?

  init(server: ServerWithConnection, ping: PingResult?) {
    self.server = server
    self.ping = ping
  }

  private var currentConnection: ServerWithCurrentConnection? {
    viewModel.currentConnection[server.server.id]
  }

  private var isCurrentDevice: Bool {
    server.server == currentConnection?.server
      && server.connection == currentConnection?.connection
  }

  private var pingResult: PingSuccess? {
    try? ping?.result.get()
  }

  @ViewBuilder
  private var pingText: some View {
    if let pingResult {
      Text(
        pingResult.details.measurement.converted(to: .milliseconds),
        format: Measurement<UnitDuration>.FormatStyle(
          width: .abbreviated,
          numberFormatStyle: .localizedDouble(locale: .current).precision(.fractionLength(1))
        )
      )
    }
  }

  var body: some View {
    HStack {
      if !server.connection.local {
        //        SFSymbol.cloud.image()
Text("CLOUD!")
      }

      Text(server.connection.address)
        .font(.body.monospaced())
        .bold(isCurrentDevice)

      pingText
        .font(.body.monospaced())
    }
    .foregroundColor(pingResult != nil ? .white : .gray)
    .padding(5)
    .background {
      if isCurrentDevice {
        PublicColor.plexTint.opacity(0.6).cornerRadius(3)
        //        Color.green.opacity(0.6).cornerRadius(3)
      } else {
        Color.black.opacity(0.2).cornerRadius(3)
      }
    }
    .disabled(ping == nil)
    .enableInjection()
  }
}
