//
//  ConnectionOverlay.swift
//
//
//  Created by Tomas Harkema on 09/06/2021.
//

import Dependencies
import Foundation
import PlexApi
import PlexCore
import PlexShared
import SwiftUI

@MainActor
public struct ConnectionOverlay: View {
  //  @Environment(\.font)
  //  private var font

  @State
  private var showOverlay = [Server.ID: Bool]()

  @Dependency(\.serverLocator)
  private var serverLocator

  @Dependency(\.storage)
  private var storage

  public init() {}

  @ViewBuilder
  private func connectionOverlay(server: ServerWithCurrentConnection) -> some View {
    let connection = server.connection
    Text("\(server.server.name) \(connection.local == true ? "Local" : "Remote") connection")
      .font(.body.bold().lowercaseSmallCaps())
      .foregroundColor(.white)
      .edgesIgnoringSafeArea(.top)
      .padding(5)
      .background(connection.local == true ? Color.green : PublicColor.plexTint)
      .cornerRadius(10)
      .task(id: serverLocator.connection) {
        do {
          showOverlay[server.server.id] = true
          try await Task.sleep(for: .seconds(5))
          showOverlay[server.server.id] = false
        } catch {
          showOverlay[server.server.id] = false
          print(error)
        }
      }
  }

  private var overlayShouldShow: Bool {
    showOverlay.values.contains { $0 == true }
  }

  public var body: some View {
    HStack {
      VStack {
        ForEach(Array(serverLocator.connection.values)) { server in
          connectionOverlay(server: server)
        }
      }
    }
    .offset(y: overlayShouldShow ? 10 : -100)
    .opacity(overlayShouldShow ? 1 : 0)
    .animation(.easeInOut, value: serverLocator.connection)
    .animation(.easeInOut, value: showOverlay)
  }
}
