//
//  VideoDetailViewModel.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import AVKit
import Foundation
//import AsyncAwaitHelpers
import PlexApi
import PlexShared
import Inject
import Processed

@MainActor @Observable
public final class VideoDetailViewModel: LoadableSupport {

  @ObservationIgnored @Injected(\.storage)
  private var storage

  @ObservationIgnored @Injected(\.api)
  private var api

  private var uuid = VideoSessionUUID(rawValue: UUID().uuidString)
  private var video: Video?
  private var lastTime: CMTime?

  public private(set) var player: LoadableState<AVPlayer> = .absent

  private var updateTimeline: LoadableState<Void> = .absent

  public init() { }

  private func createPlayer(video: Video, url: URL) async throws -> AVPlayer {
    let item = AVPlayerItem(asset: AVURLAsset(url: url))
    item.allowedAudioSpatializationFormats = .monoStereoAndMultichannel
    item.isAudioSpatializationAllowed = true

    let player = AVPlayer(playerItem: item)

    let saved = try? await self.storage.getSavedOffset(video: video)

    let time: Double = video.getProgress(storage: saved).seconds

    Task { @MainActor in
      player.seek(to: CMTime(
        seconds: time,
        preferredTimescale: 1
      ))
      player.playImmediately(atRate: 1.0)
    }

    player.addPeriodicTimeObserver(
      forInterval: CMTime(value: 10, timescale: 1),
      queue: .global(qos: .background),
      using: { time in
        Task { await self.updateTimeline(time: time) }
      }
    )
    player.isClosedCaptionDisplayEnabled = true
    player.appliesMediaSelectionCriteriaAutomatically = true

    return player
  }

  private func updateTimeline(time: CMTime) async {
    lastTime = time

    guard let video = video,
          let player = player.data
    else {
      self.reset(\.updateTimeline)
      return
    }

    await self.load(\.updateTimeline, silently: true, priority: .medium) {

      async let savedOffsetAsync = self.storage.setSavedOffset(
        progress: Progress(seconds: time.seconds, date: Date()),
        video: video
      )

      async let timelineUpdate = self.api.timeline(
        video: video,
        time: time,
        state: player.timeControlStatus == .playing ? .playing : .paused,
        deviceInfo: .current
      )

      _ = try? await savedOffsetAsync
      _ = try await timelineUpdate
    }.value
  }

  public func load(video: Video?) async {
    guard let video else {
      unload()
      return 
    }

    self.video = video
    let uuid = VideoSessionUUID(rawValue: UUID().uuidString)
    self.uuid = uuid

    await self.load(\.player, priority: .userInitiated) {
      try await self.storage.setLastPlayed(lastPlayed: video)

      let offset = await video
        .getProgress(storage: try? self.storage.getSavedOffset(video: video))
        .seconds

      let url = try await self.api.videoUrl(
        video: video,
        videoUuid: uuid,
        offset: Int(offset),
        deviceInfo: .current
      )

      return try await self.createPlayer(video: video, url: url)
    }.value
  }

  func unload() {

    if let video = video, let lastTime = lastTime, let _ = self.storage.plexToken {
      Task(priority: .background) {
        try await self.api.timeline(video: video, time: lastTime, state: .stopped,
                               deviceInfo: .current)
      }
    }
    lastTime = nil

    self.reset(\.player)
  }

  private var currentSize: String?
  public func updateBounds(bounds: CGRect?) async {
    guard let _ = video, let _ = lastTime else {
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
//      let _ = try await api.decision(videoKey: video.key, videoUuid: uuid, offset: Int(lastTime.seconds), videoResolution: newSize)
//    } catch {
//      print(error)
//    }
  }
}
