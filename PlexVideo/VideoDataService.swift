//
//  VideoDataService.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 09/06/2021.
//

import Foundation

class VideoDataService {
  func progress(for video: Video) async throws -> Progress? {
    return video.getProgress(storage: try await Storage.shared.getSavedOffset(video: video))
  }

  func getVideoList() async throws -> (onDeck: [Video], all: [Video]) {
    let sections = try await Api.shared.sections().MediaContainer.Directory.filter {
      $0.type == "movie" || $0.type == "show"
    }

    let continueWatching = try await Api.shared
      .continueWatching(contentDirectoryIDs: sections.map { $0.key })

    let videos: [Video] = try await withThrowingTaskGroup(of: [Video].self, body: { group in
      for dir in sections {
        group.async {
          (try await Api.shared.all(key: dir.key)).MediaContainer.Metadata
        }
      }
      return try await group.reduce([], +)
    })

    let localProgress: [VideoKey: Progress] =
      try await withThrowingTaskGroup(of: [VideoKey: Progress]
        .self) { group in
        for video in videos {
          if Task.isCancelled { break }
          group.async {
            if let progress = try await self.progress(for: video) {
              return [video.key: progress]
            } else {
              return [:]
            }
          }
        }

        return try await group.reduce([VideoKey: Progress]()) { prev, c in
          try Task.checkCancellation()
          var p = prev
          for (key, value) in c {
            p[key] = value
          }
          return p
        }
      }

    let continueWithLocal = continueWatching.MediaContainer.Hub.flatMap { $0.Metadata }
      .map {
        ($0, $0.getProgress(storage: localProgress[$0.key]))
      }

    let missing: [(Video, Progress)] = localProgress.filter { video in
      localProgress[video.key]?.isZero == false && !continueWithLocal
        .contains { $0.0.key == video.key }
    }
    .flatMap { k -> [(Video, Progress)] in
      if let v = videos.first(where: { k.key == $0.key }) {
        return [(v, k.value)]
      } else {
        return []
      }
    }

    let fixedContinue = [continueWithLocal, missing].joined().sorted(by: {
      $0.1.date > $1.1.date
    }).map {
      $0.0
    }

    return (fixedContinue, videos)
  }
}
