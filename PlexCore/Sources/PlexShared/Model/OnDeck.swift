//
//  OnDeck.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation
import MetaCodable

@Codable
public struct OnDeck: Equatable, Sendable {
  public let key: VideoKey
  public let title: String
  public let titleSort: String?
  public let parentTitle: String?
  public let grandparentTitle: String?
  public let thumb: String
  public let art: String

  @CodedAt("Media")
  public let media: [Media]?

  public let ratingKey: RatingKey
  public let viewOffset: NumberLike?
  public let lastViewedAt: NumberLike?
  public let leafCount: NumberLike?
  public let viewedLeafCount: NumberLike?
  public let grandparentKey: VideoKey?
  public let parentKey: VideoKey?
  public let childCount: NumberLike?
  public let grandparentThumb: String?
}

extension OnDeck: Identifiable {
  public struct ID: RawRepresentable, Hashable, Codable {
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }

  public var id: ID {
    ID(rawValue: key.id)
  }
}
