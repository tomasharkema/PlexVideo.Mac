//
//  Model.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 06/06/2021.
//

import Foundation

struct DirectoryContainer: Codable {
  let Directory: [Directory]
}

struct Root<T: Codable>: Codable {
  let MediaContainer: T

  let allowSync: String?
  let directPlayDecisionCode: Int?
  let directPlayDecisionText: String?
  let generalDecisionCode: Int?
  let generalDecisionText: String?
  let identifier: String?
  let librarySectionID: String?
  let librarySectionTitle: String?
  let librarySectionUUID: String?
  let mediaTagPrefix: String?
  let mediaTagVersion: Int?
  let transcodeDecisionCode: Int?
  let transcodeDecisionText: String?
}

struct Directory: Codable, Identifiable {
  let key: String
  let title: String
  let uuid: String
  let type: String

  var id: String {
    return uuid
  }
}

struct DoubleLikeError: Error {}

struct DoubleLike: Codable, Equatable {
  let value: Double

  init(value: Double) {
    self.value = value
  }

  init(from decoder: Decoder) throws {
    let s = try decoder.singleValueContainer()

    if let v = try? s.decode(Double.self) {
      value = v
      return
    } else if let v = try? s.decode(Int.self) {
      value = Double(v)
      return
    } else if let v = try? s.decode(String.self), let value = Double(v) {
      self.value = value
      return
    }

    throw DoubleLikeError()
  }

  func encode(to encoder: Encoder) throws {
    var s = try encoder.singleValueContainer()
    try s.encode(value)
  }
}

extension Double {
  var doubleLike: DoubleLike {
    return DoubleLike(value: self)
  }
}

struct Video: Codable, Identifiable, Equatable {
  let key: String
  let title: String
  let thumb: String
  let art: String
  let Media: [Media]?
  let ratingKey: String
  let viewOffset: DoubleLike?
  let lastViewedAt: DoubleLike?

  var id: String {
    return key
  }

  func getProgress(storage storageProgress: Progress?) -> Progress? {
    if let viewOffset = viewOffset, let lastViewedAt = lastViewedAt {
      let p = Progress(seconds: viewOffset.value / 1000, date: lastViewedAt.value)

      if let storageProgress = storageProgress {
        if storageProgress.date > p.date {
          return storageProgress
        } else {
          return p
        }
      } else {
        return p
      }
    } else {
      return storageProgress
    }
  }
}

extension Video {
  static func preview() -> Video {
    Video(key: "key", title: "Film", thumb: "Ding", art: "ding", Media: [
      PlexVideo.Media.preview(),
    ], ratingKey: "", viewOffset: DoubleLike(value: 1000),
    lastViewedAt: Date().timeIntervalSince1970.doubleLike)
  }
}

struct Media: Codable, Equatable {
  let id: DoubleLike
  let duration: DoubleLike
  let bitrate: DoubleLike
  let width: DoubleLike
  let height: DoubleLike
  let aspectRatio: DoubleLike?
  let audioChannels: DoubleLike?
  let audioCodec: String?
  let videoCodec: String?
  let videoResolution: String?
  let container: String?
  let videoFrameRate: String?
  let audioProfile: String?
  let videoProfile: String?
  let `protocol`: String?
  let indirect: String?
  let selected: Bool?
  let Part: [Part]
}

extension Media {
  static func preview() -> Media {
    return Media(
      id: DoubleLike(value: 0),
      duration: DoubleLike(value: 2000),
      bitrate: DoubleLike(value: 1000),
      width: DoubleLike(value: 1920),
      height: DoubleLike(value: 1080),
      aspectRatio: DoubleLike(value: 1.7777),
      audioChannels: DoubleLike(value: 6),
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

struct Part: Codable, Equatable {
  let id: DoubleLike
  let key: String?
  let duration: DoubleLike
  let file: String?
  let size: DoubleLike?
  let audioProfile: String?
  let container: String?
  let indexes: String?
  let videoProfile: String?
  let decision: String?
  let Stream: [Stream]?
}

struct Stream: Codable, Equatable {
  let bitrate: String?
  let codec: String?
  let colorPrimaries: String?
  let colorTrc: String?
  let `default`: String?
  let displayTitle: String
  let extendedDisplayTitle: String
  let frameRate: String?
  let height: String?
  let id: String
  let requiredBandwidths: String?
  let streamType: String
  let width: String?
  let decision: String?
  let location: String

  let format: String?
  let key: String?
  let language: String?
  let languageCode: String?
  let providerTitle: String?
  let score: String?
  let selected: String?
  let sourceKey: String?
  let transient: String?
  let userID: String?
  let bitrateMode: String?
  let channels: String?
}

struct Metadata<T: Codable>: Codable {
  let Metadata: [T]
}

struct Player: Codable {
  let machineIdentifier: String
  let address: String
}

struct Session: Codable {
  let id: String
  let bandwidth: Int
}

struct TranscodeSession: Codable {
  let key: String
  let throttled: Bool
  let complete: Bool
  let progress: Float
  let size: Int
  let speed: Int
  let duration: Int
  let context: Int
  let sourceVideoCodec: String
  let sourceAudioCodec: String
  let videoDecision: String
  let audioDecision: String
  let subtitleDecision: String
  let `protocol`: String
  let container: String
  let videoCodec: String
}

struct SessionStatus: Codable {
  let Player: Player
  let Session: Session
  let TranscodeSession: TranscodeSession
}

struct PinToken: Codable {
  let authToken: String?
  let clientIdentifier: String
  let code: String
  let createdAt: String?
  let expiresAt: String?
  let expiresIn: DoubleLike?
  let id: DoubleLike
  let newRegistration: Bool?
  let product: String?
  let trusted: Bool?
  /*
   authToken: string | null,
   clientIdentifier: string,
   code: string,
   createdAt: string,
   expiresAt: string,
   expiresIn: number,
   id: number,
   location: IPlexCodeLocation,
   newRegistration:boolean | null,
   product: string,
   trusted: boolean
   */
}


struct Device: Codable {
  let name: String
  let provides: String
  let publicAddress: String
  let connections: [Connection]
}

struct Connection: Codable {
  let `protocol`: String
  let address: String
  let port: Int
  let uri: String
  let local: Bool
  let relay: Bool
  let IPv6: Bool
}

struct Version: Codable {
  let version: String
}
