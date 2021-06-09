//
//  VideoDetail.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 05/06/2021.
//

import AVKit
import SwiftUI
import UIKit

struct VideoDetail: View {
  @StateObject var videoDetailViewModel = VideoDetailViewModel()
  @Binding var video: Video?
  @Binding var isPip: Bool
  @State var videoBounds: CGRect?

  private func load(_ video: Video?) {
    if let video = video {
      async {
        try await videoDetailViewModel.load(video: video)
      }
    } else {
      async {
        try await videoDetailViewModel.unload()
      }
    }
  }

  var body: some View {
    HStack {
      if let player = videoDetailViewModel.player {
        VideoPlayer(player: player, isPip: $isPip, videoBounds: $videoBounds)
      } else {
        Rectangle().foregroundColor(.clear)
      }
    }
    .onChange(of: video) {
      load($0)
    }
    .onChange(of: videoBounds) { bounds in
      async {
        await videoDetailViewModel.updateBounds(bounds: bounds)
      }
    }
    .onAppear {
      load(video)
    }
    .background(Color.black)
    .id(video?.key)
  }
}
