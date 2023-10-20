//
//  SettingsScreen.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 19/10/2023.
//

import SwiftUI
import PlexCore

@MainActor
public struct SettingsScreen: View {
  @State
  private var gridViewModel = VideosGridScreenViewModel()

  @State
  private var logoutMenuShowing = false

  public init() { }

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
          gridViewModel.logout()
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
