//
//  Media.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation
import InitMacro
import MetaCodable
import RawJson

@Init(public: true)
@Codable
public struct Media: Equatable, Sendable, Selecting {
  public let id: NumberLike
  public let duration: NumberLike
  public let bitrate: NumberLike
  public let width: NumberLike
  public let height: NumberLike
  public let aspectRatio: NumberLike?
  public let audioChannels: NumberLike?
  public let audioCodec: String?
  public let videoCodec: String?
  public let videoResolution: String?
  public let container: String?
  public let videoFrameRate: String?
  public let audioProfile: String?
  public let videoProfile: String?
  public let `protocol`: String?
  public let indirect: String?
  public let selected: Bool?
  public let `default`: Bool?

  @CodedAt("Part")
  public let part: [PartialCodable<Part>]?
}
