//
//  VideosViewModel.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import Foundation
import Inject
import OSLog
import PlexApi
import PlexShared
import Processed

@MainActor @Observable
public final class VideosViewModel: LoadableSupport {
  private let logger = Logger(subsystem: "PlexVideo", category: "VideosViewModel")

  @ObservationIgnored
  @Injected(\.videoDataService)
  private var service

//  @ObservationIgnored
//  @Injected(\.videosDataSource)
  private var videosDataSource = InjectedValues.get(\.videosDataSource)

  @ObservationIgnored
  @Injected(\.storage)
  private var storage

  @ObservationIgnored
  @Injected(\.api)
  private var api

  public private(set) var searchResults: LoadableState<[VideoFromServer]> = .absent

  public init() {}

  public var data: LoadableState<VideosDataSource.Data> {
    videosDataSource.data
  }

  public func reload(silently: Bool) async {
    await videosDataSource.reload(silently: silently)
  }

  public func load(silently: Bool, reload: Bool) async {
    await videosDataSource.load(silently: silently, reload: reload)
  }

  public nonisolated func searchText(_ searchText: String) async {
    let query = searchText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

    guard !query.isEmpty else {
      await reset(\.searchResults)
      return
    }

    guard query.count > 3 else {
      await reset(\.searchResults)
      return
    }

    guard case let .loaded(data) = await videosDataSource.data else {
      await reset(\.searchResults)
      return
    }

    await load(\.searchResults, silently: true, priority: .medium) {
      try Task.checkCancellation()
      let result = data.videos.filter {
        $0.video.title.lowercased().contains(query.lowercased())
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

//extension Video {
//  init(onDeck: OnDeck) {
//    self.init(
//      key: onDeck.key,
//      title: onDeck.title,
//      titleSort: onDeck.titleSort,
//      parentTitle: onDeck.parentTitle,
//      grandparentTitle: onDeck.grandparentTitle,
//      thumb: onDeck.thumb,
//      art: onDeck.art,
//      media: onDeck.media,
//      ratingKey: onDeck.ratingKey,
//      viewOffset: onDeck.viewOffset,
//      lastViewedAt: onDeck.lastViewedAt,
//      leafCount: onDeck.leafCount,
//      viewedLeafCount: onDeck.viewedLeafCount,
//      onDeck: nil,
//      grandparentKey: onDeck.grandparentKey,
//      parentKey: onDeck.parentKey,
//      childCount: onDeck.childCount,
//      grandparentThumb: onDeck.grandparentThumb
//    )
//  }
//}

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
