//
//  Video.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation
import InitMacro
import MetaCodable

@Init(public: true) @Codable
public struct Video: Identifiable, Equatable, Hashable, Sendable {
  public let key: VideoKey
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

  public var id: VideoKey {
    key
  }

  public var displayTitle: String {
    grandparentTitle ?? parentTitle ?? title
  }

  public func getProgress(storage storageProgress: Progress?) -> Progress {
    let remoteProgress = Progress(video: self)

    let viableStorageProgress: Progress? =
      if let storageProgress {
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

  public func hash(into hasher: inout Hasher) {
    hasher.combine(key.rawValue)
  }
}
