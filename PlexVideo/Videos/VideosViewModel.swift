//
//  VideosViewModel.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import Foundation

@MainActor
class VideosViewModel: ObservableObject {
  private let service = VideoDataService()
  struct Data: Equatable {
    let continueWatching: [Video]
    let videos: [Video]
  }

  @Published private(set) var data: Data?
  @Published private(set) var savedLastPlayed: Video?

  func load() async throws {
    guard let token = Storage.shared.plexToken else {
      return
    }
    async {
      savedLastPlayed = try? await Storage.shared.getLastPlayed()
    }
    async {
      let (onDeck, all) = try await service.getVideoList()
      data = Data(continueWatching: onDeck, videos: all)
    }
  }
}

actor VideoDataService {
  func progress(for video: Video) async throws -> Progress? {
    return video.getProgress(storage: try await Storage.shared.getSavedOffset(video: video))
  }

  func getVideoList() async throws -> (onDeck: [Video], all: [Video]) {
    guard let token = Storage.shared.plexToken else {
      throw NSError(domain: "NOT AUTHED", code: 0, userInfo: nil)
    }

    let videos = try await Api.shared.videos(token: token)

    let cont: [String: Progress] = try await withThrowingTaskGroup(of: [String: Progress]
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

      return try await group.reduce([String: Progress]()) { prev, c in
        try Task.checkCancellation()
        var p = prev
        for (key, value) in c {
          p[key] = value
        }
        return p
      }
    }

    let c = videos.lazy.map { video in
      (video, cont[video.key])
    }
    .filter {
      $0.1?.date != nil
    }
    .map {
      $0.0
    }
    .sorted {
      $0.lastViewedAt?.value ?? 0 > $1.lastViewedAt?.value ?? 0
    }

    return (c, videos)
  }
}

struct AsyncArray<Element>: AsyncSequence {
  let array: [Element]

  struct AsyncIterator: AsyncIteratorProtocol {
    let array: [Element]
    var index: Array<Element>.Index

    mutating func next() async -> Element? {
      let element = array[index]
      index += 1
      return element
    }
  }

  func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(array: array, index: array.startIndex)
  }
}
