//
//  SynchronizedDictionary.swift
//
//
//  Created by Tomas Harkema on 21/10/2023.
//

import Foundation

public actor SynchronizedDictionary<Key: Hashable, Value> {
  private var dict: [Key: Value] = [:]

  public subscript(key: Key) -> Value? {
    get {
      dict[key]
    }

    set {
      dict[key] = newValue
    }
  }

  public func set(_ key: Key, _ value: Value) {
    dict[key] = value
  }

  public func removeValue(forKey key: Key) {
    dict.removeValue(forKey: key)
  }
}
