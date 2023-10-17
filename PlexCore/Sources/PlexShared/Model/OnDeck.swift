//
//  OnDeck.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation
import MetaCodable

@Codable
public struct OnDeck: Identifiable, Equatable {
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

  public var id: String {
    key.rawValue
  }
}
