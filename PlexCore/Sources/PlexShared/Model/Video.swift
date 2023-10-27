//
//  Video.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation
import MetaCodable

@Codable
public struct Video: Equatable, Sendable {
  public let key: VideoKey
  public let guid: String?
  public let title: String
  public let titleSort: String?
  public let parentTitle: String?
  public let grandparentTitle: String?
  public let thumb: String?
  public let art: String?
  @CodedAt("Media")
  public let media: [Media]?
  public let ratingKey: RatingKey
  public let viewOffset: NumberLike?
  public let lastViewedAt: NumberLike?
  public let leafCount: NumberLike?
  public let viewedLeafCount: NumberLike?
  @CodedAt("OnDeck")
  public let onDeck: MetadataSingle<OnDeck>?
  public let grandparentKey: VideoKey?
  public let parentKey: VideoKey?
  public let childCount: NumberLike?
  public let grandparentThumb: String?
  public let type: String
  public let studio: String?
  public let contentRating: String?
  public let summary: String
  public let tagline: String?
  public let rating: NumberLike?
  public let year: NumberLike?
  public let duration: Double?
  public let ratingImage: String?
  public let primaryExtraKey: String?
  public let addedAt: Double
  public let updatedAt: Double?
  public let originallyAvailableAt: String?
  public let viewCount: Int?

  public var displayTitle: String {
    grandparentTitle ?? parentTitle ?? title
  }

  public func getProgress(storage storageProgress: Progress?) -> Progress {
    let remoteProgress = Progress(video: self)

    let viableStorageProgress: Progress? =
      if let storageProgress
    {
      if abs(storageProgress.date.timeIntervalSinceNow) < 7 * 24 * 60 * 60 {
        storageProgress
      } else {
        nil
      }

    } else {
      nil
    }

    switch (remoteProgress, viableStorageProgress) {
    case let (remote?, storage?) where storage.date > remote.date:
      return storage
    case let (remote?, .some(_)):
      return remote
    case let (remote?, .none):
      return remote
    case let (.none, storage?):
      return storage
    case (.none, .none):
      return .zero
    }
  }
}

extension Video: Identifiable {
  public var id: VideoKey {
    key
  }
}
