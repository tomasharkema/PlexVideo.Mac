//
//  PingResult.swift
//
//
//  Created by Tomas Harkema on 19/10/2023.
//

import Foundation
import PlexShared

public struct PingResult: Sendable {
  public let server: Root<Version>
  public let timeInterval: TimeInterval
}
