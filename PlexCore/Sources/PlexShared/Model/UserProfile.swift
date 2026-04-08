//
//  UserProfile.swift
//
//
//  Created by Tomas Harkema on 27/10/2023.
//

import Foundation
import MetaCodable

@Codable
public struct UserProfileResponse {
  @CodedAt("MyPlex")
  public let myPlex: UserProfile
}

public struct UserProfile: Codable {
  public let authToken: String
  public let username: String
  public let mappingState: String
  public let mappingError: String
  public let signInState: String
  public let publicAddress: String
  public let publicPort: Int
  public let privateAddress: String
  public let privatePort: Int
  public let subscriptionFeatures: String
  public let subscriptionActive: Bool
  public let subscriptionState: String
}
