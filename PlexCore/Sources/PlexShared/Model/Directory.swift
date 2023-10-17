//
//  Directory.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation

public struct DirectoryContainer: Codable {
  public let Directory: [Directory]
}

public struct Directory: Codable, Identifiable {
  public let key: SectionKey
  public let title: String
  public let uuid: String
  public let type: String

  public var id: String {
    uuid
  }
}
