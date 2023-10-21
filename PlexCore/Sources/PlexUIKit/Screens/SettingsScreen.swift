//
//  SettingsScreen.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 19/10/2023.
//

import SwiftUI

@MainActor
public struct SettingsScreen: View {

  @State
  private var logoutMenuShowing = false

  private let logoutHandler: @MainActor @Sendable () -> ()

  public init(logoutHandler: @MainActor @Sendable @escaping () -> ()) {
    self.logoutHandler = logoutHandler
  }

  public var body: some View {
    List {
      Button("Logout") {
        logoutMenuShowing = true
      }
    }
    .alert(
      "Logout?",
      isPresented: $logoutMenuShowing,
      actions: {
        Button(role: .destructive) {
          logoutHandler()
        } label: {
          Text("Logout")
        }
      },
      message: {
        Text("Are you sure you wanna logout?")
      }
    )
  }
}
