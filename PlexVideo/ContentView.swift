//
//  ContentView.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import SwiftUI
import PlexShared

struct ContentView: View {
  @StateObject var storage: Storage

  init(storage: Storage) {
    self._storage = .init(wrappedValue: storage)
  }

  var body: some View {
    if let _ = storage.plexToken {
      Videos()
    } else {
      Login()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(storage: .init())
  }
}
