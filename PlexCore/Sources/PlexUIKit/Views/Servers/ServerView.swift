//
//  ServerView.swift
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

  private let server: ServerAndPings

  init(
    server: ServerAndPings
  ) {
    self.server = server
  }

  private var heading: some View {
    VStack {
      HStack(alignment: .firstTextBaseline) {
        Text(server.server.name)
          .font(.title)
          .bold()

        if server.server.home {
          Image(systemName: "house")
        }

        if server.server.publicAddressMatches {
          Image(systemName: "house")
        }

        if server.server.owned {
          Text("owned")
        }

        Spacer()

        Text(server.server.lastSeenAt, format: .relative(presentation: .named))
      }
      Divider()
    }
  }

  @ViewBuilder
  private var connectionsSection: some View {
    InfoSection(
      title: "Connections",
      extra: {
        if let date = viewModel.pingerDate {
          Text(date, format: .relative(presentation: .named))
        }
      }
    ) {
      ConnectionsView(
        connections: server
      )
    }
  }

  @ViewBuilder
  private var infoSection: some View {
    if let info = viewModel.keyValueInfo[server.server.id] {
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
  private func playing(sessions: [SessionVideo]) -> some View {
    LazyVStack {
      ForEach(sessions) { session in
        NowPlayingView(session: session)
      }
    }
  }

  @ViewBuilder
  private var nowPlayingSection: some View {
    InfoSection(title: "Now Playing") {
      switch viewModel.sessions {
      case .absent, .loading:
        ProgressView()

      case let .loaded(sessions):
        if let session = sessions[server.server.id], !session.isEmpty {
          playing(sessions: session)
        } else {
          Text("Nothing is playing...")
            .foregroundColor(.white.opacity(0.6))
            .padding(.vertical)
        }

      case let .error(error):
        Text("error: \(error.localizedDescription)")
          .padding()
      }
    }
  }

  @ViewBuilder
  private var rawInfo: some View {
    if let (serverResult, capabilitiesString) = viewModel.rawResults[server.server.id] {
      InfoSection(title: "Raw JSON info", collapsible: true) {
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

      nowPlayingSection

      infoSection

      rawInfo
    }
    .padding()
    .background(Color.black.opacity(0.2))
    //    .background(Color(.plexTint).opacity(0.6))
    .cornerRadius(10)
  }
}

// #Preview {
//  ServerView(
//    server: .preview1
//  )
//  .environment(VideosViewModel())
//  .environment(ServersViewModel())
// }
