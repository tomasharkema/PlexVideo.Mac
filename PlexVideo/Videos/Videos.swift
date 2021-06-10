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

  @State var isLoading: Bool = true

  var body: some View {
    NavigationView {
      VideosGridScreen(
        viewModel: viewModel,
        video: $video
      ).overlay(ConnectionOverlay()).overlay(ProgressView().opacity(isLoading ? 1 : 0))
    }
    .navigationViewStyle(StackNavigationViewStyle())
    .overlay(
      PlayerOverlay(video: $video),
      alignment: Alignment(horizontal: .center, vertical: .bottom)
    )
    .onAppear {
      async {
        isLoading = true
        try await viewModel.load()
        isLoading = false
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
