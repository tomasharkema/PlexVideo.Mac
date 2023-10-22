//
//  PingResult.swift
//
//
//  Created by Tomas Harkema on 19/10/2023.
//

import Foundation
import PlexShared

public struct PingResult: Sendable, Hashable, Equatable {
  public let server: Server
  public let connection: Connection
  public let details: Result<PingResultDetails, PingResultError>
}

public struct PingSuccess: Sendable, Hashable, Equatable {
  public let server: Server
  public let connection: Connection
  public let details: PingResultDetails
}

public extension PingResult {
  static func success(
    server: Server, connection: Connection,
    details: PingResultDetails
  ) -> PingResult {
    PingResult(server: server, connection: connection, details: .success(details))
  }

  static func failure(
    server: Server, connection: Connection,
    error: PingResultErrorDetails
  ) -> PingResult {
    PingResult(
      server: server,
      connection: connection,
      details: .failure(PingResultError(server: server, connection: connection, details: error))
    )
  }
}

public extension PingResult {
  var result: Result<PingSuccess, PingResultError> {
    switch details {
    case let .success(details):
      .success(PingSuccess(
        server: server, connection: connection, details: details
      ))

    case let .failure(error):
      .failure(error)
    }
  }

  func get() throws -> PingSuccess {
    try result.get()
  }
}

public struct PingResultDetails: Sendable, Hashable, Equatable {
  public let result: Root<Version>
  public let interval: TimeInterval
  public let duration: Duration
  public let measurement: Measurement<UnitDuration>
}

public struct PingResultError: Sendable, Hashable, Equatable, LocalizedError {
  public let server: Server
  public let connection: Connection
  public let details: PingResultErrorDetails

  public var errorDescription: String? {
    details.errorDescription
  }
}

public enum PingResultErrorDetails: Sendable, Hashable, Equatable, LocalizedError {
  case noMetric
  case urlError(URLError)
  case otherError(any Error)

  public func hash(into hasher: inout Hasher) {
    hasher.combine(String(describing: self))
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    String(describing: lhs) == String(describing: rhs)
  }

  public var errorDescription: String? {
    switch self {
    case .noMetric:
      "Couldn't calculate ping time"

    case let .urlError(urlError):
      urlError.localizedDescription

    case let .otherError(anyError):
      anyError.localizedDescription
    }
  }
}
