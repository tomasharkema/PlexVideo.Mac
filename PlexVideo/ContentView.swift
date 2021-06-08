//
//  ContentView.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import SwiftUI

struct ContentView: View {
  @StateObject var token = Storage.shared

  var body: some View {
    if let _ = token.plexToken {
      Videos()
    } else {
      Login()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
