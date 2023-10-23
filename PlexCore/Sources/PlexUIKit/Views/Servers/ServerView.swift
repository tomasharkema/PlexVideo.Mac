//
//  DeviceView.swift
//
//
//  Created by Tomas Harkema on 20/10/2023.
//

import PlexApi
import PlexCore
import PlexShared
import SwiftUI

@MainActor
struct ServerView: View {
  @Environment(ServersViewModel.self)
  private var viewModel: ServersViewModel

  private let server: ServerAndCapabilities

  init(
    server: ServerAndCapabilities
  ) {
    self.server = server
  }

  private var heading: some View {
    VStack {
      HStack {
        Text(server.server.server.name)
          .font(.title)
          .bold()

        if server.server.server.home {
          Image(systemName: "house")
        }

        if server.server.server.publicAddressMatches {
          Image(systemName: "house")
        }

        if server.server.server.owned {
          Text("owned")
        }

        Spacer()

        Text(server.server.server.lastSeenAt, format: .relative(presentation: .named))
      }
      Divider()
    }
  }

  @ViewBuilder
  private var connectionsSection: some View {
    InfoSection(
      title: "Connections",
      extra: {
        if let date = viewModel.pings.data?.lastRun {
          Text(date, format: .relative(presentation: .named))
        }
      }
    ) {
      ConnectionsView(
        connections: server.connections
      )
    }
  }

  @ViewBuilder
  private var infoSection: some View {
    if let info = viewModel.keyValueInfo[server.server.server.id] {
      InfoSection(title: "Info", collapsible: true) {
        Table(info) {
          TableColumn("Key", value: \.key)
          TableColumn("Value", value: \.value)
        }
        .tableStyle(.inset)
        .frame(maxWidth: .infinity, minHeight: 200)
      }
    }
  }

  @ViewBuilder
  private var rawInfo: some View {
    if let (serverResult, capabilitiesString) = viewModel.rawResults[server.id] {
      InfoSection(title: "RAW JSON Result", collapsible: true) {
        VStack(alignment: .leading, spacing: 20) {
          Text("Server Result").font(.title3.bold())
          Text(serverResult)
            .monospaced()
            .padding()
            .background(Color.black)
          Divider()
          Text("Server Result").font(.title3.bold())
          Text(capabilitiesString)
            .monospaced()
            .padding()
            .background(Color.black)
        }
      }
    }
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      heading

      connectionsSection

      infoSection

      rawInfo
    }
    .padding()
    .background(Color.black.opacity(0.2))
    //    .background(Color(.plexTint).opacity(0.6))
    .cornerRadius(10)
  }
}

//#Preview {
//  ServerView(
//    server: .preview1,
//    currentConnection: .preview3,
//    pings: [
//      .preview3: .success(server: .preview1, connection: .preview3, details: .preview)
//    ]
//  )
//}
