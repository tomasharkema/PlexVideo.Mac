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
  private var showOverlay = false

  @InjectedState(\.serverLocator)
  private var serverLocator

  @ViewBuilder
  private var connectionOverlay: some View {
    HStack {
      if let connection = serverLocator.connection {
        Text("\(connection.local ? "Local" : "Remote") connection")
          .font(.subheadline.bold().lowercaseSmallCaps())
          .foregroundColor(.white)
          .edgesIgnoringSafeArea(.top)
          .padding(5)
          .background(connection.local ? Color.green : Color.yellow)
          .cornerRadius(10)
          .onAppear {
            let old = self.serverLocator.connection
            showOverlay = true
            
            Task { @MainActor in
              try await Task.sleep(time: 5)
              if old == self.serverLocator.connection {
                showOverlay = false
              }
            }
          }
      }
    }
    .onChange(of: serverLocator.connection) {
      showOverlay = serverLocator.connection != nil
    }
    .offset(y: showOverlay ? 10 : -100)
    .opacity(showOverlay ? 1 : 0)
    .animation(.easeInOut, value: serverLocator.connection)
    .animation(.easeInOut, value: showOverlay)
  }
  
  var body: some View {
    Rectangle().foregroundColor(.clear)
      .overlay(
        connectionOverlay,
        alignment: .top
      )
  }
}

