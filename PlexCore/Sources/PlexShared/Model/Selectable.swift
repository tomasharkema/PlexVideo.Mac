//
//  Selectable.swift
//
//
//  Created by Tomas Harkema on 24/10/2023.
//

import Foundation
import RawJson

public protocol Selecting {
  var selected: Bool? { get }
  var `default`: Bool? { get }
}

extension Array where Element: Selecting {
  public var selected: Element? {
    first {
      $0.selected ?? false
    } ?? first {
      $0.default ?? false
    }
  }

  public func selected(where handler: (Element) -> Bool) -> Element? {
    first {
      $0.selected ?? false && handler($0)
    } ?? first {
      $0.default ?? false && handler($0)
    } ?? first {
      handler($0)
    }
  }
}

extension PartialCodable: Selecting where ConcreteType: Selecting {
  public var selected: Bool? {
    value?.selected
  }

  public var `default`: Bool? {
    value?.`default`
  }
}

