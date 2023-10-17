//
//  Root.swift
//  
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation

public struct Root<T: Codable>: Codable {
  public let MediaContainer: T

  public let allowSync: String?
  public let directPlayDecisionCode: Int?
  public let directPlayDecisionText: String?
  public let generalDecisionCode: Int?
  public let generalDecisionText: String?
  public let identifier: String?
  public let librarySectionID: String?
  public let librarySectionTitle: String?
  public let librarySectionUUID: String?
  public let mediaTagPrefix: String?
  public let mediaTagVersion: Int?
  public let transcodeDecisionCode: Int?
  public let transcodeDecisionText: String?
}
