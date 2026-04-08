//
//  Directory.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation
import MetaCodable

@Codable
public struct DirectoryContainer: Codable {
  @CodedAt("Directory")
  public let directory: [Directory]
}

public struct Directory: Codable, Sendable {
  public let key: SectionKey
  public let title: String
  public let uuid: String
  public let type: String
}

extension Directory: Identifiable {
  public struct ID: RawRepresentable, Codable, Hashable {
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }

  public var id: ID {
    ID(rawValue: uuid)
  }
}
