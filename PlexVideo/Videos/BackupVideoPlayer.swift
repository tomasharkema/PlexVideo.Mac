//
//  BackupVideoPlayer.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 17/10/2023.
//

#if !os(iOS)

import SwiftUI
import PlexShared
import AVKit

@MainActor
struct BackupVideoPlayer: View {
  private let video: Video

//  @State private var viewModel: BackupVideoPlayerViewModel

  private let player: AVPlayer

  init(video: Video, player: AVPlayer) {
    self.video = video
    self.player = player
//    self._viewModel = .init(wrappedValue: BackupVideoPlayerViewModel(video: video))
  }

  var body: some View {
    VideoPlayer(player: player)
//      .onAppear {
//        player.play()
//      }
  }
}

//@MainActor @Observable
//final class BackupVideoPlayerViewModel {
//  private let video: Video
//
//  private(set) var player: AVPlayer?
//
//  init(video: Video) {
//    self.video = video
//  }
//
//  func start() {
//    player = AVPlayer(url: <#T##URL#>)
//  }
//}

#endif
