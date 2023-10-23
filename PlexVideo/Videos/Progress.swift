//
//  Progress.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import Foundation

struct Progress: Codable {
  let seconds: Double
  let date: Date

  init(
    seconds: Double,
    date: Date
  ) {
    self.seconds = seconds
    self.date = date
  }

  init?(video: Video) {
    if let viewOffset = video.viewOffset?.value, let lastViewedAt = video.lastViewedAt?.value {
      seconds = viewOffset / 1000
      date = Date(timeIntervalSince1970: lastViewedAt)
    } else {
      return nil
    }
  }

  var isZero: Bool {
    seconds.isZero && date.timeIntervalSince1970.isZero
  }

  static let zero = Progress(seconds: 0, date: Date(timeIntervalSince1970: 0))
}
