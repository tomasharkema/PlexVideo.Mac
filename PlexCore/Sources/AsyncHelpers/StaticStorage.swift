//
//  StaticStorage.swift
//
//
//  Created by Tomas Harkema on 21/10/2023.
//

import Foundation

typealias StaticStorageOnce = EnsureOnce<Int, Any>

actor StaticStorage {
  static let shared = StaticStorage()

  private var handlers = [HandlerLocation: StaticStorageOnce]()

  func get(location: HandlerLocation) -> StaticStorageOnce {
    if let handler = handlers[location] {
      return handler
    } else {
      let once = StaticStorageOnce(location: location)
      handlers[location] = once
      return once
    }
  }
}
