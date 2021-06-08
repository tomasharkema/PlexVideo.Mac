//
//  ContentView.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import SwiftUI

struct ContentView: View {
  @Binding var token: String?

  var body: some View {
    if let _ = token {
      Videos()
    } else {
      Login()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(token: Storage.$plexToken)
  }
}
