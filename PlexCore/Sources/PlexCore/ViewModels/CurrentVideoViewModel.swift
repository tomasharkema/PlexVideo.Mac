//
//  CurrentVideoViewModel.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import AVKit
import Combine
import Dependencies
import Foundation
import OSLog
import PlexApi
import PlexShared
import Processed
import SwiftUI
//import SwiftUIMacros

public extension EnvironmentValues {
  @Entry
  var currentVideoViewModel: CurrentVideoViewModel = .init()
}

@MainActor
@Observable
public final class CurrentVideoViewModel: LoadableSupport {
  private let logger = Logger(subsystem: "PlexVideo", category: "CurrentVideoViewModel")

  @ObservationIgnored
  @Dependency(\.storage)
  private var storage

  @ObservationIgnored
  @Dependency(\.api)
  private var api

  @ObservationIgnored
  @Dependency(\.videosDataSource)
  private var videosDataSource

  @ObservationIgnored
  private var playingCancellables = Set<AnyCancellable>()

  public var video: VideoFromServer?
  public var isPip = false
  public var isFullscreen = false
  //  public var videoBounds: CGRect? {
  //    didSet {
  //      updateBounds()
  //    }
  //  }
  private var currentSize: String?

  private var uuid = VideoSessionUUID(rawValue: UUID().uuidString)
  private var lastTime: CMTime?

  public private(set) var player: LoadableState<AVPlayer> = .absent

  private var updateTimeline: LoadableState<Void> = .absent

  private var playerStatus: AVPlayer.Status = .unknown {
    didSet {
      switch playerStatus {
      case .failed:
        if let error = player.data?.error {
          logger.error("playerStatus failed \(error)")
        } else {
          logger.error("playerStatus failed NO ERROR")
        }

      case .readyToPlay:
        logger.info("playerStatus readyToPlay")

      case .unknown:
        logger.info("playerStatus unknown")
      @unknown default:
        fatalError()
      }
    }
  }

  public nonisolated init() {}

  private func onceReadyToPlay(time: Double) {
    guard let player = player.data else {
      return
    }

    player.seek(
      to: CMTime(
        seconds: time,
        preferredTimescale: 1
      )
    )
    player.play()
  }

  private func createPlayer(video: VideoFromServer, url: URL) async throws -> AVPlayer {
    let item = AVPlayerItem(asset: AVURLAsset(url: url))
    item.allowedAudioSpatializationFormats = .monoStereoAndMultichannel
    item.isAudioSpatializationAllowed = true

    let player = AVPlayer(playerItem: item)

    let saved = try? await storage.getSavedOffset(video: video.video)

    let time: Double = video.video.getProgress(storage: saved).seconds

    player.addPeriodicTimeObserver(
      forInterval: CMTime(value: 10, timescale: 1),
      queue: .global(qos: .background),
      using: { time in
        Task { await self.updateTimeline(time: time) }
      }
    )
    //    player.isClosedCaptionDisplayEnabled = true
    player.appliesMediaSelectionCriteriaAutomatically = true

    let statusObserve = player.publisher(for: \.status)

    statusObserve.first {
      $0 == .readyToPlay
    }.sink { _ in
      Task { @MainActor in
        self.onceReadyToPlay(time: time)
      }
    }.store(in: &playingCancellables)

    statusObserve
      .sink { status in
        Task { @MainActor in
          self.playerStatus = status
        }
      }
      .store(in: &playingCancellables)

    return player
  }

  private func updateTimeline(time: CMTime) async {
    lastTime = time

    guard let video,
          let player = player.data
    else {
      reset(\.updateTimeline)
      return
    }

    await load(\.updateTimeline, silently: true, priority: .medium) {
      async let savedOffsetAsync = self.storage.setSavedOffset(
        progress: Progress(seconds: time.seconds, date: Date()),
        video: video.video
      )

      async let timelineUpdate = self.api.timeline(
        server: video.server,
        video: video.video,
        time: time,
        state: player.timeControlStatus == .playing ? .playing : .paused
      )

      _ = try? await savedOffsetAsync
      _ = try await timelineUpdate
    }.value
  }

  public func load(video: VideoFromServer?) async {
    guard let video else {
      unload()
      return
    }

    self.video = video
    let uuid = VideoSessionUUID(rawValue: UUID().uuidString)
    self.uuid = uuid

    await load(\.player, priority: .userInitiated) {
      try await self.storage.setLastPlayed(lastPlayed: video)

      let offset =
        await video.video
          .getProgress(storage: try? self.storage.getSavedOffset(video: video.video))
          .seconds

      let url = try await self.api.videoUrl(
        server: video.server,
        video: video.video,
        videoUuid: uuid,
        offset: Int(offset)
      )

      return try await self.createPlayer(video: video, url: url)
    }.value
  }

  private func unload() {
    for cancellable in playingCancellables {
      cancellable.cancel()
    }
    playingCancellables.removeAll()

    if let video, let lastTime, let _ = storage.plexToken {
      Task(priority: .background) {
        try await self.api.timeline(
          server: video.server,
          video: video.video,
          time: lastTime,
          state: .stopped
        )
      }
    }
    lastTime = nil
    video = nil
    player.data?.pause()
    reset(\.player)
  }

  public func open(video: VideoFromServer) {
    Task {
      do {
        guard let newVideo = try await self.openVideo(video: video) else {
          return
        }

        withTransaction(.init(animation: .easeInOut)) {
          self.video = video
        }
      } catch {
        logger.error("open video error: \(error)")
      }
    }
  }

  private func openVideo(video: VideoFromServer) async throws -> VideoFromServer? {
    do {
      let onDeckResponse = try await api.onDeck(
        server: video.server,
        ratingKey: video.video.ratingKey
      )

      if let res = onDeckResponse.mediaContainer.metadata.first?.onDeck?.metadata {
        let video = videosDataSource.getVideo(by: res.key)
        assertionFailure(String(describing: video))
        return video
      } else {
        return video
      }

    } catch {
      logger.error("open video error: \(error)")
      return video
    }
  }

  //  private func updateBounds(bounds: CGRect?) async {
  //    guard let _ = video, let _ = lastTime else {
  //      return
  //    }
  //
  //    let defaultSize = "4096x2160"
  //
  //    var newSize: String
  //
  //    if let bounds = bounds {
  //      if bounds.width.isZero || bounds.height.isZero {
  //        newSize = defaultSize
  //      } else {
  //        newSize = "\(Int(bounds.width * 2))x\(Int(bounds.height * 2))"
  //      }
  //    } else {
  //      newSize = defaultSize
  //    }
  //
  //    if currentSize == newSize {
  //      return
  //    }
  //    currentSize = newSize
  ////    do {
  ////      let _ = try await api.decision(videoKey: video.key, videoUuid: uuid, offset:
  /// Int(lastTime.seconds), videoResolution: newSize)
  ////    } catch {
  ////      print(error)
  ////    }
  //  }

  public func stopPlaying() {
    unload()
  }

  public func fullscreen() {
    //    withTransaction(.init(animation: .linear)) {
    isFullscreen = true
    //    }
  }

  public var screenWidth: CGFloat {
#if os(iOS)
    return UIScreen.main.bounds.width
#endif
#if os(macOS)
    return NSScreen.main?.frame.width ?? 1920
#endif
  }

  public var minHeight: CGFloat {
    let widescreen: CGFloat = (16 / 9)
    let aspectRatio: CGFloat = video?.video.media?.first?.aspectRatio?.value ?? widescreen
    return min(screenWidth - 50, 400) * (1 / aspectRatio)
  }
}
