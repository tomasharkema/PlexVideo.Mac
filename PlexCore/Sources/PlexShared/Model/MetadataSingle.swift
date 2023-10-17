//
//  MetadataSingle.swift
//  
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation

public struct MetadataSingle<T: Codable & Equatable>: Codable, Equatable {
  
  public let Metadata: T
}
