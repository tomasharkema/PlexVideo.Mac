//
//  DeviceInfo.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

// import Foundation

public struct DeviceInfo: Sendable {
//  @MainActor
//  static let shared = DeviceInfo()

  public let platform = "tvOS" // UIDevice().systemName
  // let platform = "Windows"
  public let name: String // UIDevice().name
  public let device = "iPhone"
  public let version: String
  public let appVersion = "0.1"
  public let product = "PlexVideo"

  public init(name: String) {
    self.name = name
    version = "17.0"
  }
}
