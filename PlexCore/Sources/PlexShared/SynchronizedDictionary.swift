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
      self.dict[key] = newValue
    }
  }

  public func set(_ key: Key, _ value: Value) {
    self.dict[key] = value
  }

  public func removeValue(forKey key: Key) {
    self.dict.removeValue(forKey: key)
  }
}
