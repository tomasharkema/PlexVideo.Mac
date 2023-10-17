//
//  ConnectionOverlay.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 09/06/2021.
//

import Foundation
import SwiftUI
//import AsyncAwaitHelpers
import PlexApi
import Inject

@MainActor
struct ConnectionOverlay: View {
  @State 
  var showOverlay: Bool = false

  @State private var viewModel = ConnectionOverlayViewModel()

  var body: some View {
    Rectangle().foregroundColor(.clear).overlay(
      HStack {
        if let connection = viewModel.serverLocator.connection {
          Text("\(connection.local ? "Local" : "Remote") connection")
            .font(.subheadline.bold().lowercaseSmallCaps())
            .foregroundColor(.white)
            .edgesIgnoringSafeArea(.top)
            .padding(5)
            .background(connection.local ? Color.green : Color.yellow)
            .cornerRadius(10)
            .onAppear {
              let old = self.viewModel.serverLocator.connection
              showOverlay = true

                Task { @MainActor in
                  try await Task.sleep(time: 5)
                  if old == self.viewModel.serverLocator.connection {
                    showOverlay = false
                  }
              }
            }
        }
      }
      .onChange(of: viewModel.serverLocator.connection) {
        showOverlay = $0 != nil
      }
      .offset(y: showOverlay ? 10 : -100)
      .opacity(showOverlay ? 1 : 0)
      .animation(.easeInOut, value: viewModel.serverLocator.connection)
      .animation(.easeInOut, value: showOverlay),
      alignment: .top
    )
  }
}

@MainActor @Observable
final class ConnectionOverlayViewModel {
  @ObservationIgnored @Injected(\.serverLocator)
  var serverLocator
}
