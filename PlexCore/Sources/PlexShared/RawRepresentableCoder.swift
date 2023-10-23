//
//  RawRepresentableCoder.swift
//
//
//  Created by Tomas Harkema on 23/10/2023.
//

import Foundation
import MetaCodable

struct RawRepresentableCoder<RawType: RawRepresentable>: HelperCoder
where RawType.RawValue == String {
  func decode(from decoder: any Decoder) throws -> RawType {
    let single = try decoder.singleValueContainer()
    guard let value = try RawType(rawValue: single.decode(String.self)) else {
      throw DecodingError.valueNotFound(
        String.self,
        .init(codingPath: decoder.codingPath, debugDescription: "")
      )
    }
    return value
  }
}
