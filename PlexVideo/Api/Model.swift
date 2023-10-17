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

struct SectionKey: RawRepresentable, Codable {
  var rawValue: String
}

struct Directory: Codable, Identifiable {
  let key: SectionKey
  let title: String
  let uuid: String
  let type: String

  var id: String {
    uuid
  }
}

struct DoubleLikeError: Error {}

struct NumberLike: Codable, Equatable {
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
    } else if let v = try? s.decode(Bool.self) {
      value = v ? 1 : 0
      return
    }

    throw DoubleLikeError()
  }

  func encode(to encoder: Encoder) throws {
    var s = encoder.singleValueContainer()
    try s.encode(value)
  }
}

extension Double {
  var doubleLike: NumberLike {
    NumberLike(value: self)
  }
}

struct MetadataSingle<T: Codable & Equatable>: Codable, Equatable {
  let Metadata: T
}

struct OnDeck: Codable, Identifiable, Equatable {
  let key: VideoKey
  let title: String
  let titleSort: String?
  let parentTitle: String?
  let grandparentTitle: String?
  let thumb: String
  let art: String
  let Media: [Media]?
  let ratingKey: RatingKey
  let viewOffset: NumberLike?
  let lastViewedAt: NumberLike?
  let leafCount: NumberLike?
  let viewedLeafCount: NumberLike?
  let grandparentKey: VideoKey?
  let parentKey: VideoKey?
  let childCount: NumberLike?
  let grandparentThumb: String?

  var id: String {
    key.rawValue
  }
}

struct RatingKey: RawRepresentable, Codable, Equatable {
  var rawValue: String
}

struct VideoKey: RawRepresentable, Codable, Equatable, Identifiable, Hashable {
  var rawValue: String

  var id: String {
    rawValue
  }
}

struct Video: Codable, Identifiable, Equatable, Hashable {
  let key: VideoKey
  let title: String
  let titleSort: String?
  let parentTitle: String?
  let grandparentTitle: String?
  let thumb: String?
  let art: String?
  let Media: [Media]?
  let ratingKey: RatingKey
  let viewOffset: NumberLike?
  let lastViewedAt: NumberLike?
  let leafCount: NumberLike?
  let viewedLeafCount: NumberLike?
  let OnDeck: MetadataSingle<OnDeck>?
  let grandparentKey: VideoKey?
  let parentKey: VideoKey?
  let childCount: NumberLike?
  let grandparentThumb: String?

  var id: String {
    key.rawValue
  }

  var displayTitle: String {
    grandparentTitle ?? parentTitle ?? title
  }

  func getProgress(storage storageProgress: Progress?) -> Progress {
    let remoteProgress = Progress(video: self)

    let viableStorageProgress: Progress?
    if let storageProgress = storageProgress {
      if abs(storageProgress.date.timeIntervalSinceNow) < 7 * 24 * 60 * 60 {
        viableStorageProgress = storageProgress
      } else {
        viableStorageProgress = nil
      }

    } else {
      viableStorageProgress = nil
    }

    switch (remoteProgress, viableStorageProgress) {
    case let (remote?, storage?) where storage.date > remote.date:
      return storage
    case let (remote?, .some(_)):
      return remote
    case let (remote?, .none):
      return remote
    case let (.none, storage?):
      return storage
    case (.none, .none):
      return .zero
    }
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(key.rawValue)
  }
}

extension Video {
  static func preview(id: String = UUID().uuidString) -> Video {
    Video(
      key: VideoKey(rawValue: id), title: "Dit is een titel van een hele lange film",
      titleSort: "is",
      parentTitle: nil, grandparentTitle: nil,
      thumb: "https://static.posters.cz/image/750/posters/pulp-fiction-cover-i1288.jpg",
      art: "ding",
      Media: [
        PlexVideo.Media.preview(),
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

struct Media: Codable, Equatable {
  let id: NumberLike
  let duration: NumberLike
  let bitrate: NumberLike
  let width: NumberLike
  let height: NumberLike
  let aspectRatio: NumberLike?
  let audioChannels: NumberLike?
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

struct Part: Codable, Equatable {
  let id: NumberLike
  let key: String?
  let duration: NumberLike?
  let file: String?
  let size: NumberLike?
  let audioProfile: String?
  let container: String?
  let indexes: String?
  let videoProfile: String?
  let decision: String?
  let Stream: [Stream]?
}

struct Stream: Codable, Equatable {
  let bitrate: NumberLike?
  let codec: String?
  let colorPrimaries: String?
  let colorTrc: String?
  let `default`: NumberLike?
  let displayTitle: String
  let extendedDisplayTitle: String
  let frameRate: NumberLike?
  let height: NumberLike?
  let id: NumberLike
  let requiredBandwidths: String?
  let streamType: NumberLike
  let width: NumberLike?
  let decision: String?
  let location: String?

  let format: String?
  let key: String?
  let language: String?
  let languageCode: String?
  let providerTitle: String?
  let score: String?
  let selected: NumberLike?
  let sourceKey: String?
  let transient: String?
  let userID: String?
  let bitrateMode: String?
  let channels: NumberLike?
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

struct TranscodeSessions: Codable {
  let TranscodeSession: [TranscodeSession]
}

struct TranscodeSession: Codable {
  let key: String?
  let throttled: Bool?
  let complete: Bool?
  let progress: Float
  let size: Int
  let speed: Float
  let duration: Int
  let context: String
  let sourceVideoCodec: String
  let sourceAudioCodec: String
  let videoDecision: String
  let audioDecision: String
  let subtitleDecision: String?
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
  let expiresIn: NumberLike?
  let id: NumberLike
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

struct Connection: Codable, Equatable {
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

struct Hub<T: Codable>: Codable {
  let Hub: [Metadata<T>]
}
