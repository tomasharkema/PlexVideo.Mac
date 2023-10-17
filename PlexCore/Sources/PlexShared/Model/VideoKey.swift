//
//  VideoKey.swift
//  
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation

public struct VideoKey: RawRepresentable, Codable, Equatable, Identifiable, Hashable {
  public var rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public var id: String {
    rawValue
  }
}
