//
//  VideoDataService.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 09/06/2021.
//

import Foundation

// FIXME: Tryout asyncDetached! Should be async let. But that crashes the compiler

class VideoDataService {
  nonisolated func progress(for video: Video) async throws -> Progress {
    return video.getProgress(storage: try await Storage.shared.getSavedOffset(video: video))
  }

  private func getSections() async throws -> [Directory] {
    return try await Api.shared.sections().MediaContainer.Directory.filter {
      $0.type == "movie" || $0.type == "show"
    }
  }

  func getContinueWatching(sections: Task
    .Handle<[Directory], Error>) async throws -> [(VideoKey, Progress)]
  {
    return try await whenAll(tasks: Api.shared
      .continueWatching(contentDirectoryIDs: sections.get().map { $0.key })
      .MediaContainer.Hub
      .flatMap { $0.Metadata }
      .map { v in
        asyncDetached(priority: .userInitiated) {
          try await (v.key, v.getProgress(storage: self.progress(for: v)))
        }
      })
  }

  func fetchVideos(sections: Task.Handle<[Directory], Error>) async throws -> [Video] {
    return try await Array(whenAll(tasks: sections.get().map { s in
      asyncDetached(priority: .userInitiated) {
        (try await Api.shared.all(key: s.key)).MediaContainer.Metadata
      }
    }).joined())
  }

  func getVideoList() async throws -> (onDeck: [Video], all: [Video]) {
    let sections = asyncDetached(priority: .userInitiated) { try await getSections() }
    let continueWatchingResultKeyValue = asyncDetached(priority: .userInitiated) {
      try await getContinueWatching(sections: asyncDetached(priority: .userInitiated) {
        try await sections.get()
      })
    }
    let continueWatching = asyncDetached(priority: .userInitiated) {
      Dictionary(uniqueKeysWithValues: try await continueWatchingResultKeyValue.get())
    }

    let videos = asyncDetached(priority: .userInitiated) {
      try await fetchVideos(sections: sections)
    }

    let videosByKey = asyncDetached(priority: .userInitiated) {
      try await Dictionary(uniqueKeysWithValues: videos.get().map {
        ($0.key, $0)
      })
    }

    let progressArrayMissing =
      asyncDetached(priority: .userInitiated) {
        try await Array(whenAll(tasks: videos.get().map { video in
          asyncDetached(priority: .userInitiated) { () -> [(VideoKey, Progress)] in
            let progress = try await video.getProgress(storage: self.progress(for: video))
            let cw = try await continueWatching.get()

            if !progress.isZero, cw[video.key] == nil {
              return [(video.key, progress)]
            } else {
              return []
            }
          }
        }).joined())
      }

    let fixedContinue: Task.Handle<[Video], Error> = asyncDetached(priority: .userInitiated) {
      let vbk = try await videosByKey.get()
      return try await [continueWatchingResultKeyValue.get(), progressArrayMissing.get()].joined()
        .sorted {
          $0.1.date > $1.1.date
        }
        .flatMap {
          vbk[$0.0].map { [$0] } ?? []
        }
    }

    return try await (fixedContinue.get(), videos.get())
  }
}
