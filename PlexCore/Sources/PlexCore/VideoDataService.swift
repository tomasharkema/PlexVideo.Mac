//
//  VideoDataService.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 09/06/2021.
//

import Foundation
import PlexApi
import PlexShared
import Inject

public final class VideoDataService: Sendable {

  @Injected(\.api)
  private var api

  @Injected(\.storage)
  private var storage

  nonisolated func progress(for video: Video) async throws -> PlexShared.Progress {
    assert(!Thread.isMainThread)
    return video.getProgress(storage: try await self.storage.getSavedOffset(video: video))
  }

  private func getSections(deviceInfo: DeviceInfo) async throws -> [Directory] {
    try await self.api.sections(deviceInfo: deviceInfo).mediaContainer.directory.filter {
      $0.type == "movie" || $0.type == "show"
    }
  }

  func getContinueWatching(sections: [Directory], deviceInfo: DeviceInfo) async throws -> [Video] {
    try await self.api
      .continueWatching(contentDirectoryIDs: sections.map(\.key), deviceInfo: deviceInfo)
      .mediaContainer.hub
      .flatMap(\.metadata)
  }

  func getContinueWatchingAndProgress(
    sections: [Directory], deviceInfo: DeviceInfo
  ) async throws -> [(VideoKey, PlexShared.Progress)] {

    try await getContinueWatching(sections: sections, deviceInfo: deviceInfo)
      .map { watchingVideo in
        {
          Task(priority: .userInitiated) {
            try await (watchingVideo.key, watchingVideo.getProgress(storage: self.progress(for: watchingVideo)))
          }
        }
      }.whenAll()
  }

  func fetchVideos(sections: [Directory], deviceInfo: DeviceInfo) async throws -> [Video] {
    try await Array(sections.map { section in
      Task {
        (try await self.api.all(key: section.key, deviceInfo: deviceInfo)).mediaContainer.metadata
      }
    }.whenAll().joined())
  }

  public func getVideoList(deviceInfo: DeviceInfo) async throws -> (onDeck: [Video], all: [Video]) {
    let sections = try await getSections(deviceInfo: deviceInfo)

    async let videosAsync = fetchVideos(sections: sections, deviceInfo: deviceInfo)
    async let continueWatchingResultKeyValueAsync =
      getContinueWatchingAndProgress(sections: sections, deviceInfo: deviceInfo)

    let (videos, continueWatchingResultKeyValue) = try await (
      videosAsync,
      continueWatchingResultKeyValueAsync
    )

    let continueWatching = [VideoKey: PlexShared.Progress](uniqueKeysWithValues: continueWatchingResultKeyValue)
    let videosByKey = Dictionary(uniqueKeysWithValues: videos.map {
      ($0.key, $0)
    })

    async let progressArrayMissing = Array(videos.map { video in
      Task { () -> [(VideoKey, PlexShared.Progress)] in
          let progress = try await video
            .getProgress(storage: self.progress(for: video))

          if !progress.isZero, continueWatching[video.key] == nil {
            return [(video.key, progress)]
          } else {
            return []
          }
      }
    }.whenAll().joined())

    let fixedContinue = try await [continueWatchingResultKeyValue, progressArrayMissing]
      .joined()
      .sorted {
        $0.1.date > $1.1.date
      }
      .flatMap {
        videosByKey[$0.0].map { [$0] } ?? []
      }

    let videosSorted = videos.sorted {
      $0.titleSort ?? $0.title < $1.titleSort ?? $1.title
    }

    return (fixedContinue, videosSorted)
  }
}

public extension InjectedValues {
  var videoDataService: VideoDataService {
    get { Self[VideoDataServiceKey.self] }
    set { Self[VideoDataServiceKey.self] = newValue }
  }
}

private struct VideoDataServiceKey: InjectionKey {
  static var currentValue: VideoDataService = .init()
}
