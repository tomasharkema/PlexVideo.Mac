//
//  CodableRawRepresentable.swift
//
//
//  Created by Tomas Harkema on 24/10/2023.
//

import Foundation
import OSLog
import FirebaseCrashlytics

fileprivate let logger = Logger(subsystem: "PlexVideo", category: "CodableWrapper")

public struct CodableWrapper<Value: Codable> {
  public let value: Value
}

extension CodableWrapper: RawRepresentable {
  public typealias RawValue = String

  public init?(rawValue: RawValue) {
    do {
      guard let data = rawValue.data(using: .utf8) else {
        throw NullError()
      }
      value = try JSONDecoder().decode(Value.self, from: data)
    } catch {
      Crashlytics.crashlytics().record(error: error)
      logger.error("CodableWrapper \(String(describing: Self.self)) error: \(error)")
      return nil
    }
  }

  public var rawValue: RawValue {
    do {
      let data = try JSONEncoder().encode(value)
      guard let string = String(data: data, encoding: .utf8) else {
        throw NullError()
      }
      return string
    } catch {
      Crashlytics.crashlytics().record(error: error)
      logger.error("CodableWrapper \(String(describing: Self.self)) error \(error)")
      return ""
    }
  }
}
