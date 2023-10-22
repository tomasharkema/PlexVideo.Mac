//
//  Metadata.swift
//
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation
import MetaCodable

@Codable
public struct Metadata<MetadataType: Codable> {
  @CodedAt("Metadata")
  public let metadata: [MetadataType]
}

extension Metadata: Sendable where MetadataType: Sendable {}

@Codable
public struct Hub<MetadataType: Codable> {
  @CodedAt("Hub")
  public let hub: [Metadata<MetadataType>]
}
