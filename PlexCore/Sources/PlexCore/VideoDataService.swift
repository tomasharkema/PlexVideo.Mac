//
//  VideoDataService.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 09/06/2021.
//

import Foundation
import Inject
import PlexApi
import PlexShared

public final class VideoDataService: Sendable {
  @Injected(\.api)
  private var api

  @Injected(\.storage)
  private var storage

  nonisolated func progress(for video: Video) async throws -> PlexShared.Progress {
    try await video.getProgress(storage: storage.getSavedOffset(video: video))
  }

  private func getSections() async throws -> [Directory] {
    try await api.sections().mediaContainer.directory.filter {
      $0.type == "movie" || $0.type == "show"
    }
  }

  func getContinueWatching(sections: [Directory]) async throws -> [Video] {
    try await api
      .continueWatching(contentDirectoryIDs: sections.map(\.key))
      .mediaContainer.hub
      .flatMap(\.metadata)
  }

  func getContinueWatchingAndProgress(
    sections: [Directory]
  ) async throws -> [(VideoKey, PlexShared.Progress)] {
    try await withThrowingTaskGroup(
      of: (VideoKey, PlexShared.Progress).self, returning: [(VideoKey, PlexShared.Progress)].self
    ) { group in
      let videos = try await getContinueWatching(sections: sections)

      for watchingVideo in videos {
        group.addTask {
          try await (
            watchingVideo.key,
            watchingVideo.getProgress(storage: self.progress(for: watchingVideo))
          )
        }
      }

      return try await group.reduce(into: .init()) {
        $0.append($1)
      }
    }
  }

  func fetchVideos(sections: [Directory], reload: Bool) async throws -> [Video] {
    try await withThrowingTaskGroup(of: [Video].self) { group in
      for section in sections {
        group.addTask {
          try await self.api.all(key: section.key, reload: reload).mediaContainer.metadata
        }
      }

      return try await group.reduce(into: .init()) {
        $0.append(contentsOf: $1)
      }
    }
  }

  private func progressMissing(
    videos: [Video],
    continueWatching: [VideoKey: PlexShared.Progress]
  ) async throws -> [(VideoKey, PlexShared.Progress)] {
    try await withThrowingTaskGroup(
      of: (VideoKey, PlexShared.Progress)?.self,
      returning: [(VideoKey, PlexShared.Progress)].self
    ) { group in
      for video in videos {
        group.addTask {
          let progress = try await video
            .getProgress(storage: self.progress(for: video))

          if !progress.isZero, continueWatching[video.key] == nil {
            return (video.key, progress)
          } else {
            return nil
          }
        }
      }

      return try await group.reduce(into: .init()) { prev, element in
        if let element {
          prev.append(element)
        }
      }
    }
  }

  public func getVideoList(reload: Bool) async throws -> (onDeck: [Video], all: [Video]) {
    let sections = try await getSections()

    async let videosAsync = fetchVideos(sections: sections, reload: reload)
    async let continueWatchingAsync = getContinueWatchingAndProgress(sections: sections)

    let (videos, continueWatchingResultKeyValue) = try await (
      videosAsync,
      continueWatchingAsync
    )

    let continueWatching =
      [VideoKey: PlexShared.Progress](uniqueKeysWithValues: continueWatchingResultKeyValue)
    let videosByKey = Dictionary(uniqueKeysWithValues: videos.map {
      ($0.key, $0)
    })

    async let progressArrayMissing = progressMissing(
      videos: videos,
      continueWatching: continueWatching
    )

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
  static var currentValue: VideoDataService? = .init()
}
