//
//  DeviceInfo+current.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation

#if canImport(UIKit)

  import UIKit

  extension DeviceInfo {
    @MainActor
    public static let current = DeviceInfo(name: UIDevice.current.name)
  }

#elseif canImport(AppKit)

  import AppKit

  extension DeviceInfo {
    @MainActor
    public static let current = DeviceInfo(name: Host.current().localizedName ?? "")
  }

#endif
