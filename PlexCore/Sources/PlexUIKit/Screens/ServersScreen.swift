//
//  ServersScreen.swift
//
//
//  Created by Tomas Harkema on 20/10/2023.
//

import PlexApi
import PlexCore
import PlexShared
import SwiftUI

@MainActor
public struct ServersScreen: View {
  @Environment(ServersViewModel.self)
  private var viewModel

  public init() {}

  public var body: some View {
    ScrollView {
      VStack {
        ForEach(viewModel.servers) { server in
          ServerView(server: server)
            .id(server.id)
        }
      }
      .padding()
    }
    .navigationTitle("Servers")
    .environment(viewModel)
    .onAppear {
      viewModel.start()
    }
    .onDisappear {
      viewModel.stop()
    }
  }
}

// #Preview {
//  ServersScreen(
//    servers: [
//      .preview1
//      //      .preview2,
//    ],
//    currentConnection: .preview1,
//    pings: [:]
//  )
//  .background(Color.black)
//  .preferredColorScheme(.dark)
// }
