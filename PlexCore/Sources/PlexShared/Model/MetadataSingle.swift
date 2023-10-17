//
//  MetadataSingle.swift
//  
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation
import MetaCodable

@Codable
public struct MetadataSingle<T: Codable & Equatable>: Equatable {
  
  @CodedAt("Metadata")
  public let metadata: T
}
