//
//  CodableRawRepresentable.swift
//
//
//  Created by Tomas Harkema on 24/10/2023.
//

#if canImport(FirebaseCrashlytics)
  public import FirebaseCrashlytics
#endif

import Foundation
import OSLog

private let logger = Logger(subsystem: "PlexVideo", category: "CodableWrapper")

public struct CodableWrapper<Value: Codable> {
  public let value: Value
}

extension CodableWrapper: RawRepresentable {
  public typealias RawValue = String

  public init?(rawValue: RawValue) {
    do {
//      guard let data = rawValue.data(using: .utf8) else {
//        throw NullError()
//      }
      let data = Data(rawValue.utf8)
      value = try JSONDecoder.default.decode(Value.self, from: data)
    } catch {
      #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().record(error: error)
      #endif
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
      #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().record(error: error)
      #endif
      logger.error("CodableWrapper \(String(describing: Self.self)) error \(error)")
      return ""
    }
  }
}
