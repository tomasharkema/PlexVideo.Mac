//
//  RootView.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import SwiftUI
import PlexShared
import Inject
import PlexCore

struct RootView: View {

  @InjectedState(\.storage)
  private var storage: Storage

  init() { }

  var body: some View {
    if let _ = storage.plexToken {
      MainView()
    } else {
      Login()
    }
  }
}
