//
//  RootView.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import Dependencies
import PlexCore
import PlexShared
import SwiftUI

struct RootView: View {
  @Dependency(\.storage)
  private var storage

  init() {}

  var body: some View {
    if let _ = storage.plexToken {
      MainView()
    } else {
      Login()
    }
  }
}
