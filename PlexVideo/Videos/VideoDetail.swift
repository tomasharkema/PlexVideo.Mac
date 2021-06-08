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
  let video: Video?
  @Binding var isPip: Bool

  var body: some View {
    HStack {
      if let player = videoDetailViewModel.player {
        VideoPlayer(player: player, isPip: $isPip)
          .onDisappear {
            async {
              try await videoDetailViewModel.unload()
            }
          }
      } else if let video = video {
        Rectangle().foregroundColor(.clear)
          .onAppear {
            asyncDetached {
              try await videoDetailViewModel.load(video: video)
            }
          }
      }
    }
    .background(Color.black)
    .id(video?.key)
  }
}
