//
//  VideosViewModel.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import Foundation
import PlexApi
import Inject
import PlexShared
import Processed
import OSLog

@MainActor @Observable
public final class VideosViewModel: ObservableObject, LoadableSupport {

  private let logger = Logger(subsystem: "PlexVideo", category: "VideosViewModel")

  @ObservationIgnored @Injected(\.videoDataService)
  private var service

  @ObservationIgnored @Injected(\.storage)
  private var storage

  @ObservationIgnored @Injected(\.api)
  private var api

  public private(set) var data: LoadableState<Data> = .absent

  public private(set) var searchResults: LoadableState<[Video]> = .absent

  public private(set) var savedLastPlayed: Video?

  public nonisolated init() {}

  public func load(silently: Bool) async {
    _ = await self.load(\.data, silently: silently, priority: .userInitiated) { yield in
      async let lastPlayer = self.storage.getLastPlayed()
      async let (onDeck, all) = self.service.getVideoList(deviceInfo: .current)

      do {
        self.savedLastPlayed = try await lastPlayer
      } catch {
        self.logger.error("Videos load error: \(error)")
        self.savedLastPlayed = nil
      }

      do {
        yield(.loaded(try await Data(continueWatching: onDeck, videos: all)))
      } catch {
        self.logger.error("Videos load error: \(error)")
        throw error
      }
    }.value
  }

  public nonisolated func searchText(_ searchText: String) async {

    let query = searchText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

    guard !query.isEmpty else {
      await self.reset(\.searchResults)
      return
    }

    guard query.count > 3 else {
      await self.reset(\.searchResults)
      return
    }

    guard case let .loaded(data) = await self.data else {
      await self.reset(\.searchResults)
      return
    }

    await self.load(\.searchResults, silently: true, priority: .medium) {
      try Task.checkCancellation()
      let result = data.videos.filter {
        return $0.title.lowercased().contains(query.lowercased())
      }
      try Task.checkCancellation()
      return result
    }.value
  }

//  func setSearchResult(_ s: [Video]) {
//    searchResults = s
//  }

  public func resetLastPlayed() {
    Task(priority: .background) {
      try await self.storage.setLastPlayed(lastPlayed: nil)
    }
  }
}

extension VideosViewModel {
  public struct Data: Equatable {
    public let continueWatching: [Video]
    public let videos: [Video]
  }
}

extension Video {
  init(onDeck: OnDeck) {
    self.init(
      key: onDeck.key,
      title: onDeck.title,
      titleSort: onDeck.titleSort,
      parentTitle: onDeck.parentTitle,
      grandparentTitle: onDeck.grandparentTitle,
      thumb: onDeck.thumb,
      art: onDeck.art,
      media: onDeck.media,
      ratingKey: onDeck.ratingKey,
      viewOffset: onDeck.viewOffset,
      lastViewedAt: onDeck.lastViewedAt,
      leafCount: onDeck.leafCount,
      viewedLeafCount: onDeck.viewedLeafCount,
      onDeck: nil,
      grandparentKey: onDeck.grandparentKey,
      parentKey: onDeck.parentKey,
      childCount: onDeck.childCount,
      grandparentThumb: onDeck.grandparentThumb
    )
  }
}

// enum ViewError: LocalizedError, Equatable {
//  case error(any LocalizedError)
//
//  static func == (lhs: ViewError, rhs: ViewError) -> Bool {
//    switch (lhs, rhs) {
//    case let (.error(lhs), .error(rhs)):
//      return lhs.localizedDescription == rhs.localizedDescription
//    }
//  }
//
//  func errorDescription() -> String? {
//    switch self {
//    case let .error(error):
//      return error.errorDescription
//    }
//  }
//
//  var localizedDescription: String? {
//    switch self {
//    case let .error(error):
//      return error.localizedDescription
//    }
//  }
// }
