//
//  VideoDataService.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 09/06/2021.
//

import AsyncAwaitHelpers
import Foundation
import Inject
import PlexApi
import PlexShared

// FIXME: Tryout asyncDetached! Should be async let. But that crashes the compiler

final class VideoDataService {
  @Injected(\.api)
  private var api

  @Injected(\.storage)
  private var storage

  nonisolated func progress(for video: Video) async throws -> PlexShared.Progress {
    assert(!Thread.isMainThread)
    return try await video.getProgress(storage: storage.getSavedOffset(video: video))
  }

  private func getSections() async throws -> [Directory] {
    try await api.sections(deviceInfo: .current).MediaContainer.Directory.filter {
      $0.type == "movie" || $0.type == "show"
    }
  }

  func getContinueWatching(sections: [Directory]) async throws -> [Video] {
    try await api
      .continueWatching(contentDirectoryIDs: sections.map(\.key), deviceInfo: .current)
      .MediaContainer.Hub
      .flatMap(\.Metadata)
  }

  func getContinueWatchingAndProgress(sections: [Directory]) async throws
    -> [(VideoKey, PlexShared.Progress)]
  {
    try await getContinueWatching(sections: sections)
      .map { v in
        {
          Task(priority: .userInitiated) {
            try await (v.key, v.getProgress(storage: self.progress(for: v)))
          }
        }
      }.whenAll()
  }

  func fetchVideos(sections: [Directory]) async throws -> [Video] {
    try await Array(sections.map { s in
      Task {
        try await (self.api.all(key: s.key, deviceInfo: .current)).MediaContainer.Metadata
      }
    }.whenAll().joined())
  }

  func getVideoList() async throws -> (onDeck: [Video], all: [Video]) {
    let sections = try await getSections()

    async let videosAsync = fetchVideos(sections: sections)
    async let continueWatchingResultKeyValueAsync =
      getContinueWatchingAndProgress(sections: sections)

    let (videos, continueWatchingResultKeyValue) = try await (
      videosAsync,
      continueWatchingResultKeyValueAsync
    )

    let continueWatching =
      [VideoKey: PlexShared.Progress](uniqueKeysWithValues: continueWatchingResultKeyValue)
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
