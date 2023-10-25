//
//  Stream.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation

public enum StreamType: Int, Codable, Sendable {
  case video = 1
  case audio = 2
  case subtitles = 3
}

public struct Stream: Codable, Equatable, Sendable, Selecting {
  public let bitrate: NumberLike?
  public let codec: String?
  public let colorPrimaries: String?
  public let colorTrc: String?
  public let `default`: Bool?
  public let displayTitle: String
  public let extendedDisplayTitle: String
  public let frameRate: NumberLike?
  public let height: NumberLike?
  public let id: NumberLike
  public let requiredBandwidths: String?
  public let streamType: StreamType
  public let width: NumberLike?
  public let decision: String?
  public let location: String?

  public let format: String?
  public let key: String?
  public let language: String?
  public let languageCode: String?
  public let providerTitle: String?
  public let score: String?
  public let selected: Bool?
  public let sourceKey: String?
  public let transient: String?
  public let userID: String?
  public let bitrateMode: String?
  public let channels: NumberLike?

  public var bitrateMeasurement: Measurement<UnitInformationStorage>? {
    (bitrate?.value).map {
      Measurement(value: $0, unit: .kilobits)
    }
  }
}
