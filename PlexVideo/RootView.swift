//
//  RootView.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import Inject
import PlexCore
import PlexShared
import SwiftUI

struct RootView: View {
  @InjectedState(\.storage)
  private var storage: Storage

  init() {}

  var body: some View {
    if let _ = storage.plexToken {
      MainView()
    } else {
      Login()
    }
  }
}
