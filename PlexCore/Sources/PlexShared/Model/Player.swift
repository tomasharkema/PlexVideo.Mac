//
//  Player.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation

public struct Player: Codable, Hashable, Equatable {
  public let address: String
  public let device: String?
  public let machineIdentifier: String
  public let model: String
  public let platform: String
  public let platformVersion: String
  public let product: String
  public let profile: String
  public let remotePublicAddress: String
  public let state: String
  public let title: String
  public let vendor: String?
  public let version: String
  public let local: Bool
  public let relayed: Bool
  public let secure: Bool
  public let userID: Int
}
