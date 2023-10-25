//
//  Model.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 06/06/2021.
//

import Foundation
import MetaCodable
import PlexShared

public struct PinToken: Codable {
  public let authToken: String?
  public let clientIdentifier: String
  public let code: String
  public let createdAt: String?
  public let expiresAt: String?
  public let expiresIn: NumberLike?
  public let id: Int
  public let newRegistration: Bool?
  public let product: String?
  public let trusted: Bool?
}
