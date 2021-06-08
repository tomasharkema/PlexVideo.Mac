//
//  VideoDetailViewModel.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import AVKit
import Foundation

@MainActor
class VideoDetailViewModel: ObservableObject {
  private var uuid = UUID().uuidString
  private var video: Video?
  private var lastTime: CMTime?
  @Published var player: AVPlayer? = nil

  private var oldTask: Task.Handle<Void, Error>?

  private func updateTimeline(s: CMTime) {
    lastTime = s
    oldTask?.cancel()
    oldTask = asyncDetached {
      guard let video = await video, let token = Storage.plexToken,
            let player = await player else { return }

      asyncDetached {
        try await Storage.setSavedOffset(
          progress: Progress(seconds: s.seconds, date: Date().timeIntervalSince1970),
          video: video
        )
      }

      let r = try await Api.shared.timeline(
        video: video,
        time: s,
        state: player.timeControlStatus == .playing ? .playing : .paused,
        token: token
      )
      print(r)
    }
  }

  func load(video: Video) async throws {
    self.video = video
    uuid = UUID().uuidString
    guard let token = Storage.plexToken else { return }

    try await Storage.setLastPlayed(lastPlayed: video)

    let offset = await video.getProgress(storage: try? Storage.getSavedOffset(video: video))?
      .seconds ?? 0

    let url = try await Api.shared.videoUrl(
      video: video,
      token: token,
      uuid: uuid,
      offset: Int(offset)
    )

    let player = AVPlayer()
    let asset = AVURLAsset(url: url)

    let item = AVPlayerItem(asset: asset)
    player.replaceCurrentItem(with: item)

    let saved = try? await Storage.getSavedOffset(video: video)

    let time: Double = video.getProgress(storage: saved)?.seconds ?? 0
    asyncDetached {
      player.seek(to: CMTime(
        seconds: time,
        preferredTimescale: 1
      ))
    }
    player.playImmediately(atRate: 1.0)

    player.addPeriodicTimeObserver(
      forInterval: CMTime(value: 10, timescale: 1),
      queue: .global(qos: .background),
      using: { s in
        self.updateTimeline(s: s)
      }
    )
    player.isClosedCaptionDisplayEnabled = true
    player.appliesMediaSelectionCriteriaAutomatically = true
    self.player = player
  }

  func unload() async throws {
    if let token = Storage.plexToken, let video = video, let lastTime = lastTime {
      asyncDetached(priority: .background) {
        await Api.shared.timeline(video: video, time: lastTime, state: .stopped, token: token)
      }
    }
    lastTime = nil

    player?.pause()
    player = nil
  }
}
