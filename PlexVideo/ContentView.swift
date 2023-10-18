//
//  ContentView.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import SwiftUI
import PlexShared
import Inject
import PlexCore

struct ContentView: View {
  
  @InjectedState(\.storage)
  private var storage: Storage

  public init() { }
  
  var body: some View {
    if let _ = storage.plexToken {
      Videos()
    } else {
      Login()
    }
  }
}

//struct ContentView_Previews: PreviewProvider {
//  static var previews: some View {
//    ContentView(/*storage: .init()*/)
//  }
//}
