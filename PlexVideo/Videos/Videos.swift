//
//  Videos.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import Foundation
import SwiftUI

struct Videos: View {
  @StateObject var viewModel = VideosViewModel()

  @State var video: Video?

  var body: some View {
    ZStack(alignment: Alignment(horizontal: .center, vertical: .bottom)) {
      NavigationView {
        VideosGrid(
          viewModel: viewModel,
          video: $video
        ).overlay(ConnectionOverlay())
      }
      .navigationViewStyle(StackNavigationViewStyle()).zIndex(1)

      PlayerOverlay(video: $video).zIndex(100)
    }
    .onAppear {
      async {
        try await viewModel.load()
      }
    }
    .onChange(of: viewModel.savedLastPlayed) {
      if video == nil {
        video = $0
      }
    }
    .onChange(of: video) {
      if $0 == nil {
        asyncDetached(priority: .background) {
          try await Storage.shared.setLastPlayed(lastPlayed: nil)
        }
      }
    }
  }
}
