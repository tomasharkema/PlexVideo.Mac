//
//  Part.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

//import Foundation

public struct Part: Codable, Equatable {
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
  public let Stream: [Stream]?
}
