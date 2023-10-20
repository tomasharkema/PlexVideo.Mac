//
//  DeviceResponse.swift
//  
//
//  Created by Tomas Harkema on 17/10/2023.
//

import MetaCodable

@Codable
public struct DeviceResponse: Sendable, Hashable {
  public let name: String
  public let provides: String
  public let publicAddress: String
  public let connections: [Connection]
}

extension DeviceResponse: Identifiable {
  public var id: Int {
    hashValue
  }
}
