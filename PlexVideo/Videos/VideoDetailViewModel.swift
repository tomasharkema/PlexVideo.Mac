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
  private var uuid = VideoSessionUUID(rawValue: UUID().uuidString)
  private var video: Video?
  private var lastTime: CMTime?
  @Published var player: AVPlayer? = nil

  private var oldTask: Task.Handle<Void, Error>?

  private func updateTimeline(s: CMTime) {
    lastTime = s
    oldTask?.cancel()
    oldTask = async {
      guard let video = video,
            let player = player
      else {
        return
      }
      async {
        try await Storage.shared.setSavedOffset(
          progress: Progress(seconds: s.seconds, date: Date()),
          video: video
        )
      }

      let r = await Api.shared.timeline(
        video: video,
        time: s,
        state: player.timeControlStatus == .playing ? .playing : .paused
      )
      print(r)
    }
  }

  func load(video: Video) async throws {
    if video != self.video {
      try await unload()
    }
    self.video = video
    let uuid = VideoSessionUUID(rawValue: UUID().uuidString)
    self.uuid = uuid

    try await Storage.shared.setLastPlayed(lastPlayed: video)

    let offset = await video.getProgress(storage: try? Storage.shared.getSavedOffset(video: video))
      .seconds

    let url = try await Api.shared.videoUrl(
      video: video,
      videoUuid: uuid,
      offset: Int(offset)
    )

    let item = AVPlayerItem(asset: AVURLAsset(url: url))
    item.allowedAudioSpatializationFormats = .monoStereoAndMultichannel
    item.isAudioSpatializationAllowed = true

    let player = AVPlayer(playerItem: item)

    let saved = try? await Storage.shared.getSavedOffset(video: video)

    let time: Double = video.getProgress(storage: saved).seconds
    asyncDetached {
      player.seek(to: CMTime(
        seconds: time,
        preferredTimescale: 1
      ))
    }
//    player.playImmediately(atRate: 1.0)

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
    if let video = video, let lastTime = lastTime, let token = Storage.shared.plexToken {
      asyncDetached(priority: .background) {
        await Api.shared.timeline(video: video, time: lastTime, state: .stopped)
      }
    }
    lastTime = nil

    player?.pause()
    player = nil
  }

  private var currentSize: String?
  func updateBounds(bounds: CGRect?) async {
    guard let video = video, let lastTime = lastTime else {
      return
    }

    let defaultSize = "4096x2160"

    var newSize: String

    if let bounds = bounds {
      if bounds.width.isZero || bounds.height.isZero {
        newSize = defaultSize
      } else {
        newSize = "\(Int(bounds.width * 2))x\(Int(bounds.height * 2))"
      }
    } else {
      newSize = defaultSize
    }

    if currentSize == newSize {
      return
    }
    currentSize = newSize
//    do {
//      let _ = try await Api.shared.decision(videoKey: video.key, videoUuid: uuid, offset: Int(lastTime.seconds), videoResolution: newSize)
//    } catch {
//      print(error)
//    }
  }
}
