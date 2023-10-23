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

  @Injected(\.serverLocator)
  private var serverLocator

  nonisolated func progress(for video: VideoFromServer) async throws -> PlexShared.Progress {
    try await video.video.getProgress(storage: storage.getSavedOffset(video: video.video))
  }

  private func getSections(server: ServerWithCurrentConnection) async throws -> [Directory] {
    try await api.sections(server: server).mediaContainer.directory.filter {
      $0.type == "movie" || $0.type == "show"
    }
  }

  func getContinueWatching(server: ServerWithCurrentConnection, sections: [Directory]) async throws
    -> [VideoFromServer]
  {
    try await api
      .continueWatching(server: server, contentDirectoryIDs: sections.map(\.key))
      .mediaContainer.hub
      .flatMap(\.metadata)
      .map {
        VideoFromServer(video: $0, server: server)
      }
  }

  func getContinueWatchingAndProgress(
    server: ServerWithCurrentConnection,
    sections: [Directory]
  ) async throws -> [(VideoFromServer.ID, PlexShared.Progress)] {
    try await withThrowingTaskGroup(
      of: (VideoFromServer.ID, PlexShared.Progress).self,
      returning: [(VideoFromServer.ID, PlexShared.Progress)].self
    ) { group in
      let videos = try await getContinueWatching(server: server, sections: sections)

      for watchingVideo in videos {
        group.addTask {
          try await (
            watchingVideo.id,
            watchingVideo.video.getProgress(storage: self.progress(for: watchingVideo))
          )
        }
      }

      return try await group.reduce(into: .init()) {
        $0.append($1)
      }
    }
  }

  func fetchVideos(server: ServerWithCurrentConnection, sections: [Directory], reload: Bool)
    async throws -> [VideoFromServer]
  {
    try await withThrowingTaskGroup(of: [VideoFromServer].self) { group in
      for section in sections {
        group.addTask {
          try await self.api.all(server: server, key: section.key, reload: reload).mediaContainer
            .metadata.map {
              VideoFromServer(video: $0, server: server)
            }
        }
      }

      return try await group.reduce(into: .init()) {
        $0.append(contentsOf: $1)
      }
    }
  }

  private func progressMissing(
    videos: [VideoFromServer],
    continueWatching: [VideoFromServer.ID: PlexShared.Progress]
  ) async throws -> [(VideoFromServer.ID, PlexShared.Progress)] {
    try await withThrowingTaskGroup(
      of: (VideoFromServer.ID, PlexShared.Progress)?.self,
      returning: [(VideoFromServer.ID, PlexShared.Progress)].self
    ) { group in
      for video in videos {
        group.addTask {
          let progress =
            try await video.video.getProgress(storage: self.progress(for: video))

          if !progress.isZero, continueWatching[video.id] == nil {
            return (video.id, progress)
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

  public func getVideoList(reload: Bool) async throws -> (
    onDeck: [VideoFromServer], all: [VideoFromServer]
  ) {

    let server = try await self.serverLocator.root()

    let sections = try await getSections(server: server)

    async let videosAsync = fetchVideos(server: server, sections: sections, reload: reload)
    async let continueWatchingAsync = getContinueWatchingAndProgress(
      server: server,
      sections: sections
    )

    let (videos, continueWatchingResultKeyValue) = try await (
      videosAsync,
      continueWatchingAsync
    )

    let continueWatching = [VideoFromServer.ID: PlexShared.Progress](
      uniqueKeysWithValues: continueWatchingResultKeyValue
    )
    let videosByKey: [VideoFromServer.ID: VideoFromServer] = Dictionary(
      uniqueKeysWithValues: videos.map {
        ($0.id, $0)
      }
    )

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
      $0.video.titleSort ?? $0.video.title < $1.video.titleSort ?? $1.video.title
    }

    return (fixedContinue, videosSorted)
  }
}

extension InjectedValues {
  public var videoDataService: VideoDataService {
    get { Self[VideoDataServiceKey.self] }
    set { Self[VideoDataServiceKey.self] = newValue }
  }
}

private struct VideoDataServiceKey: InjectionKey {
  static var currentValue: VideoDataService? = .init()
}
