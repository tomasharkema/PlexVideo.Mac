//
//  Videos.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import Foundation
import SwiftUI
import PlexApi
import PlexShared
import PlexCore

@MainActor
struct Videos: View {
  @State 
  private var viewModel = VideosViewModel()

  @State 
  private var video: Video?

  var body: some View {
    NavigationStack {
      VideosGridScreen(
        viewModel: $viewModel,
        video: $video
      )
      .overlay(ConnectionOverlay())
      //.overlay(ProgressView().opacity(viewModel.data.isLoading ? 1 : 0))
    }
    .overlay(
      PlayerOverlay(video: $video),
      alignment: Alignment(horizontal: .center, vertical: .bottom)
    )
    .task {
      await viewModel.load(silently: false)
    }
    .onChange(of: viewModel.savedLastPlayed) {
      // on startup, start the last saved playing video
      if video == nil {
        video = viewModel.savedLastPlayed
      }
    }
    .onChange(of: video) {
      if video == nil {
        self.viewModel.resetLastPlayed()
      }
    }
  }
}
