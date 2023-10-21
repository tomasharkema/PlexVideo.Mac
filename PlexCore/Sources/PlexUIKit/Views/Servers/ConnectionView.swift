//
//  ConnectionView.swift
//  
//
//  Created by Tomas Harkema on 20/10/2023.
//

import SwiftUI
import PlexApi
import PlexShared

struct ConnectionsView: View {
  private let connections: [Connection]
  private let currentConnection: Connection?
  private let pings: [Connection: PingResult]

  init(connections: [Connection], currentConnection: Connection?, pings: [Connection: PingResult]) {
    self.connections = connections
    self.currentConnection = currentConnection
    self.pings = pings
  }

  var body: some View {
    VStack(alignment: .leading) {
      ForEach(connections) { connection in
        ConnectionView(connection: connection, currentConnection: currentConnection, ping: pings[connection])
      }
    }
    .padding()
    .background(.black.opacity(0.6))
    .cornerRadius(10)
  }
}

struct ConnectionView: View {
  private let connection: Connection
  private let currentConnection: Connection?
  private let ping: PingResult?

  init(connection: Connection, currentConnection: Connection?, ping: PingResult?) {
    self.connection = connection
    self.currentConnection = currentConnection
    self.ping = ping
  }

  private var isCurrentDevice: Bool {
    connection == currentConnection
  }

  @ViewBuilder
  private var pingText: some View {
    switch ping?.result {
    case .some(.success(let success)):
      Text(
        success.details.measurement.converted(to: .milliseconds),
        format: Measurement<UnitDuration>.FormatStyle(
          width: .abbreviated,
          numberFormatStyle: .localizedDouble(locale: .current).precision(.fractionLength(1))
        )
      )

    case .failure(let error):
      //        Text(error.localizedDescription)
      Text("ERROR!")

    case .none:
      //        Text("NO RESULT")
      EmptyView()

    }
  }

  var body: some View {
    HStack {

      Text(connection.address)
        .font(.body.monospaced())
        .bold(isCurrentDevice)
      Text(connection.local ? "LOCAL" : "REMOTE")
        .font(.body.monospaced())

      Spacer()

      pingText
        .font(.body.monospaced())

    }
    .foregroundColor(.white)
    .padding(5)
    .background {
      if isCurrentDevice {
        Color.green.opacity(0.6).cornerRadius(3)
      } else {
        Color.clear
      }
    }
    .disabled(ping == nil)
  }
}
