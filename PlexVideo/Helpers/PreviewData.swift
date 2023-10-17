//
//  PreviewData.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 17/10/2023.
//

import Foundation
import PlexShared

extension Video {
  static func preview(id: String = UUID().uuidString) -> Video {
    Video(
      key: VideoKey(rawValue: id), title: "Dit is een titel van een hele lange film",
      titleSort: "is",
      parentTitle: nil, grandparentTitle: nil,
      thumb: "https://static.posters.cz/image/750/posters/pulp-fiction-cover-i1288.jpg",
      art: "ding",
      Media: [
        PlexShared.Media.preview(),
      ],
      ratingKey: RatingKey(rawValue: id),
      viewOffset: NumberLike(value: 1000),

      lastViewedAt: NumberLike(value: 1000),
      leafCount: NumberLike(value: 1000),
      viewedLeafCount: Date().timeIntervalSince1970.doubleLike,
      OnDeck: nil,
      grandparentKey: nil, parentKey: nil, childCount: nil, grandparentThumb: nil
    )
  }
}

extension Media {
  static func preview() -> Media {
    Media(
      id: NumberLike(value: 0),
      duration: NumberLike(value: 2000),
      bitrate: NumberLike(value: 1000),
      width: NumberLike(value: 1920),
      height: NumberLike(value: 1080),
      aspectRatio: NumberLike(value: 1.7777),
      audioChannels: NumberLike(value: 6),
      audioCodec: "ac3",
      videoCodec: "HEVC",
      videoResolution: "1920x1080",
      container: "mkv",
      videoFrameRate: "24p",
      audioProfile: "dts",
      videoProfile: "2",
      protocol: "mkv",
      indirect: "0",
      selected: true,
      Part: [
      ]
    )
  }
}
