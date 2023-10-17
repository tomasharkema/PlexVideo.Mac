//
//  Part.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import MetaCodable

@Codable
public struct Part: Equatable, Sendable {
  public let id: NumberLike
  public let key: String?
  public let duration: NumberLike?
  public let file: String?
  public let size: NumberLike?
  public let audioProfile: String?
  public let container: String?
  public let indexes: String?
  public let videoProfile: String?
  public let decision: String?

  @CodedAt("Stream")
  public let stream: [Stream]?
}
