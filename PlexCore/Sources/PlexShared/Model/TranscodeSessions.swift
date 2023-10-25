//
//  TranscodeSessions.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation
import MetaCodable

@Codable
public struct TranscodeSessions: Sendable, Equatable, Hashable {
  @CodedAt("TranscodeSession")
  public let transcodeSession: [TranscodeSession]
}

public struct TranscodeSession: Codable, Sendable, Equatable, Hashable {
  public let key: String?
  public let throttled: Bool?
  public let complete: Bool?
  public let progress: Float
  public let size: Int
  public let speed: Float
  public let duration: Int
  public let context: String
  public let sourceVideoCodec: String?
  public let sourceAudioCodec: String?
  public let videoDecision: String?
  public let audioDecision: String?
  public let subtitleDecision: String?
  public let `protocol`: String
  public let container: String
  public let videoCodec: String?
  public let audioCodec: String?

  public let transcodeHwRequested: Bool?
  public let transcodeHwDecoding: String?
  public let transcodeHwEncoding: String?
  public let transcodeHwDecodingTitle: String?
  public let transcodeHwFullPipeline: Bool?
  public let transcodeHwEncodingTitle: String?
}

//"key": "/transcode/sessions/08sasi0sog15wpujup3m7hyf",
//"throttled": true,
//"complete": false,
//"progress": 59.599998474121094,
//"size": -22,
//"speed": 0,
//"error": false,
//"duration": 9651840,
//"context": "streaming",
//"sourceVideoCodec": "h264",
//"sourceAudioCodec": "dca",
//"videoDecision": "transcode",
//"audioDecision": "transcode",
//"subtitleDecision": "copy",
//"protocol": "http",
//"container": "mkv",
//"videoCodec": "h264",
//"audioCodec": "opus",
//"audioChannels": 6,
//"transcodeHwRequested": true,
//"transcodeHwDecoding": "nvdec",
//"transcodeHwEncoding": "nvenc",
//"transcodeHwDecodingTitle": "NVIDIA (NVDEC)",
//"transcodeHwFullPipeline": true,
//"transcodeHwEncodingTitle": "NVIDIA (NVENC)",
//"timeStamp": 1698175767.611311,
//"maxOffsetAvailable": 7819.04,
//"minOffsetAvailable": 2069
