//
//  DeviceInfo+current.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation
import PlexApi

#if canImport(UIKit)

import UIKit

public extension DeviceInfo {

  static var current = DeviceInfo(name: UIDevice.current.name)

}

#elseif canImport(AppKit)

import AppKit

public extension DeviceInfo {

  static var current = DeviceInfo(name: Host.current().localizedName ?? "")

}

#endif
