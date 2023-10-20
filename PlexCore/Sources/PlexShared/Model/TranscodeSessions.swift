//
//  TranscodeSessions.swift
//  
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation
import MetaCodable

@Codable
public struct TranscodeSessions: Sendable {
  @CodedAt("TranscodeSession")
  public let transcodeSession: [TranscodeSession]
}

public struct TranscodeSession: Codable, Sendable {
  public let key: String?
  public let throttled: Bool?
  public let complete: Bool?
  public let progress: Float
  public let size: Int
  public let speed: Float
  public let duration: Int
  public let context: String
  public let sourceVideoCodec: String
  public let sourceAudioCodec: String
  public let videoDecision: String
  public let audioDecision: String
  public let subtitleDecision: String?
  public let `protocol`: String
  public let container: String
  public let videoCodec: String
}
