//
//  Progress.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import Foundation

public struct Progress: Codable, Sendable {

  public static let zero = Progress(seconds: 0, date: Date(timeIntervalSince1970: 0))

  public let seconds: Double
  public let date: Date

  public init(
    seconds: Double,
       date: Date
  ) {
    self.seconds = seconds
    self.date = date
  }

  public init?(video: Video) {
    if let viewOffset = video.viewOffset?.value, let lastViewedAt = video.lastViewedAt?.value {
      seconds = viewOffset / 1000
      date = Date(timeIntervalSince1970: lastViewedAt)
    } else {
      return nil
    }
  }

  public var isZero: Bool {
    seconds.isZero && date.timeIntervalSince1970.isZero
  }
}
