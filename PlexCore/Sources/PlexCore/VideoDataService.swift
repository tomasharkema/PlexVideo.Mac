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

struct ListResult {
  var videos: [VideoFromServer]
  var progress: [(VideoFromServer.ID, PlexShared.Progress)]
}

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

  private func getSections(server: ServerWithCurrentConnection,
                           onlyCached: Bool) async throws -> [Directory]
  {
    try await api.sections(server: server, onlyCached: onlyCached).mediaContainer.directory.filter {
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

  func fetchVideos(
    server: ServerWithCurrentConnection,
    sections: [Directory],
    reload: Bool,
    onlyCached: Bool
  )
    async throws -> [VideoFromServer]
  {
    try await withThrowingTaskGroup(of: [VideoFromServer].self) { group in
      for section in sections {
        group.addTask {
          try await self.api.all(
            server: server,
            key: section.key,
            reload: reload,
            onlyCached: onlyCached
          ).mediaContainer
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

  public func getVideoList(reload: Bool, onlyCached: Bool) async throws -> (
    onDeck: [VideoFromServer], all: [VideoFromServer]
  ) {
    let servers = try await serverLocator.getServers()

    let lists: ListResult = try await withThrowingTaskGroup(of: ListResult.self) { group in
      for serv in servers {
        group.addTask {
          let server = try await self.serverLocator.root(server: serv.server)
          try Task.checkCancellation()
          let sections = try await self.getSections(server: server, onlyCached: onlyCached)
          try Task.checkCancellation()
          async let videosAsync = self.fetchVideos(
            server: server,
            sections: sections,
            reload: reload,
            onlyCached: onlyCached
          )
          async let continueWatchingAsync = self.getContinueWatchingAndProgress(
            server: server,
            sections: sections
          )
          try Task.checkCancellation()
          return try await ListResult(videos: videosAsync, progress: continueWatchingAsync)
        }
      }

      return try await group.reduce(into: ListResult(videos: [], progress: [])) { prev, curr in
        prev.progress.append(contentsOf: curr.progress)
        prev.videos.append(contentsOf: curr.videos)
      }
    }
    try Task.checkCancellation()

    let continueWatching = [VideoFromServer.ID: PlexShared.Progress](
      uniqueKeysWithValues: lists.progress
    )
    let videosByKey: [VideoFromServer.ID: VideoFromServer] = Dictionary(
      uniqueKeysWithValues: lists.videos.map {
        ($0.id, $0)
      }
    )

    try Task.checkCancellation()

    async let progressArrayMissing = progressMissing(
      videos: lists.videos,
      continueWatching: continueWatching
    )

    try Task.checkCancellation()
    let fixedContinue = try await [lists.progress, progressArrayMissing]
      .joined()
      .sorted {
        $0.1.date > $1.1.date
      }
      .flatMap {
        videosByKey[$0.0].map { [$0] } ?? []
      }

    let videosSorted = lists.videos.sorted {
      $0.video.titleSort ?? $0.video.title < $1.video.titleSort ?? $1.video.title
    }
    try Task.checkCancellation()
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
