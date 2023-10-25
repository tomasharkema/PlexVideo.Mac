//
//  SessionStatus.swift
//
//
//  Created by Tomas Harkema on 17/10/2023.
//

import Foundation
import MetaCodable
import RawJson

@Codable
public struct SessionStatus: Sendable, Equatable {
  @CodedAt("Player")
  public let player: PartialCodable<Player>?

  @CodedAt("Session")
  public let session: PartialCodable<Session>?

  @CodedAt("TranscodeSession")
  public let transcodeSession: PartialCodable<TranscodeSession>?

  @CodedAt("User")
  public let user: PartialCodable<User>?

  @CodedAt("Media")
  public let media: [PartialCodable<Media>]?

  public let key: String
  public let sessionKey: String
  public let title: String
  public let viewOffset: TimeInterval
}

extension SessionStatus: Identifiable {
  public struct ID: RawRepresentable, Hashable, Codable {
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }

  public var id: ID {
    ID(rawValue: sessionKey)
  }
}

extension PartialCodable: Hashable where ConcreteType: Hashable { 
  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
    hasher.combine(raw)
  }
}

extension SessionStatus {
  public var videoID: VideoKey {
    VideoKey(rawValue: key)
  }
}

extension PartialCodable: @unchecked Sendable where ConcreteType: Sendable { }
