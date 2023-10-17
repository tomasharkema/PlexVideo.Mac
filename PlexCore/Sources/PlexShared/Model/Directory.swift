//
//  Directory.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation
import MetaCodable

@Codable
public struct DirectoryContainer {
  @CodedAt("Directory")
  public let directory: [Directory]
}

public struct Directory: Codable, Identifiable, Sendable {
  public let key: SectionKey
  public let title: String
  public let uuid: String
  public let type: String

  public var id: String {
    uuid
  }
}
