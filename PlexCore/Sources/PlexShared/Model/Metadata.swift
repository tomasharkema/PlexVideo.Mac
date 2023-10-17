//
//  Metadata.swift
//  
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation

public struct Metadata<MetadataType: Codable>: Codable {
  public let Metadata: [MetadataType]
}

public struct Hub<MetadataType: Codable>: Codable {
  public let Hub: [Metadata<MetadataType>]
}
