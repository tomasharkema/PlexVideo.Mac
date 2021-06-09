//
//  VideosViewModel.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import Foundation

enum ViewError: LocalizedError, Equatable {
  case error(Error)

  static func == (lhs: ViewError, rhs: ViewError) -> Bool {
    switch (lhs, rhs) {
    case let (.error(l), .error(r)):
      return l.localizedDescription == r.localizedDescription
    }
  }
}

@MainActor
class VideosViewModel: ObservableObject {
  private let service = VideoDataService()

  @Published private(set) var data: Result<Data, ViewError>?
  @Published private(set) var savedLastPlayed: Video?

  func load() async throws {
    async {
      savedLastPlayed = try? await Storage.shared.getLastPlayed()
    }
    async {
      do {
        let (onDeck, all) = try await service.getVideoList()
        data = .success(Data(continueWatching: onDeck, videos: all))
      } catch {
        print(error)
        data = .failure(ViewError.error(error))
      }
    }
  }

  func openVideo(video: Video) async throws -> Video? {
    do {
      let onDeckResponse = try await Api.shared.onDeck(ratingKey: video.ratingKey)

      if let res = onDeckResponse.MediaContainer.Metadata.first?.OnDeck?.Metadata {
        return Video(onDeck: res)
      } else {
        return video
      }

    } catch {
      return video
    }
  }
}

extension VideosViewModel {
  struct Data: Equatable {
    let continueWatching: [Video]
    let videos: [Video]
  }
}

extension Video {
  init(onDeck: OnDeck) {
    key = onDeck.key
    title = onDeck.title
    thumb = onDeck.thumb
    art = onDeck.art
    Media = onDeck.Media
    ratingKey = onDeck.ratingKey
    viewOffset = onDeck.viewOffset
    lastViewedAt = onDeck.lastViewedAt
    leafCount = onDeck.leafCount
    viewedLeafCount = onDeck.viewedLeafCount
    OnDeck = nil
    grandparentKey = onDeck.grandparentKey
    parentKey = onDeck.parentKey
    childCount = onDeck.childCount
    grandparentThumb = onDeck.grandparentThumb
    parentTitle = onDeck.parentTitle
    grandparentTitle = onDeck.grandparentTitle
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
