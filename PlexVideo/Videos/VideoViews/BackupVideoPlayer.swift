//
//  BackupVideoPlayer.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 17/10/2023.
//

#if !os(iOS)

  import AVKit
  import PlexCore
  import PlexShared
  import SwiftUI

  @MainActor
  struct BackupVideoPlayer: View {
    @Environment(CurrentVideoViewModel.self)
    private var viewModel

    var body: some View {
      if let player = viewModel.player.data {
        VideoPlayer(player: player)
      } else {
        ProgressView()
      }
    }
  }

#endif
