//
//  Stream.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation

public struct Stream: Codable, Equatable {
  public let bitrate: NumberLike?
  public let codec: String?
  public let colorPrimaries: String?
  public let colorTrc: String?
  public let `default`: NumberLike?
  public let displayTitle: String
  public let extendedDisplayTitle: String
  public let frameRate: NumberLike?
  public let height: NumberLike?
  public let id: NumberLike
  public let requiredBandwidths: String?
  public let streamType: NumberLike
  public let width: NumberLike?
  public let decision: String?
  public let location: String?

  public let format: String?
  public let key: String?
  public let language: String?
  public let languageCode: String?
  public let providerTitle: String?
  public let score: String?
  public let selected: NumberLike?
  public let sourceKey: String?
  public let transient: String?
  public let userID: String?
  public let bitrateMode: String?
  public let channels: NumberLike?
}
