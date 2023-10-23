//
//  PingResult.swift
//
//
//  Created by Tomas Harkema on 19/10/2023.
//

import Foundation
import PlexShared

public struct PingResult: Sendable, Equatable {
  public let serverWithConnection: ServerWithConnection
  public let details: Result<PingResultDetails, PingResultError>
}

public struct PingSuccess: Sendable, Equatable {
  public let serverWithConnection: ServerWithConnection
  public let details: PingResultDetails
}

extension PingResult {
  public static func success(
    serverWithConnection: ServerWithConnection,
    details: PingResultDetails
  ) -> PingResult {
    PingResult(serverWithConnection: serverWithConnection, details: .success(details))
  }

  public static func failure(
    serverWithConnection: ServerWithConnection,
    error: PingResultErrorDetails
  ) -> PingResult {
    PingResult(
      serverWithConnection: serverWithConnection,
      details: .failure(PingResultError(serverWithConnection: serverWithConnection, details: error))
    )
  }
}

extension PingResult {
  public var result: Result<PingSuccess, PingResultError> {
    switch details {
    case let .success(details):
      .success(
        PingSuccess(
          serverWithConnection: serverWithConnection,
          details: details
        )
      )

    case let .failure(error):
      .failure(error)
    }
  }

  public func get() throws -> PingSuccess {
    try result.get()
  }
}

public struct PingResultDetails: Sendable, Hashable, Equatable {
  public let result: Root<Capabilities>?
  public let interval: TimeInterval

  public var duration: Duration {
    .seconds(interval)
  }

  public var measurement: Measurement<UnitDuration> {
    .init(value: interval, unit: .seconds)
  }
}

public struct PingResultError: Sendable, Equatable, LocalizedError {
  public let serverWithConnection: ServerWithConnection
  public let details: PingResultErrorDetails

  public var errorDescription: String? {
    details.errorDescription
  }
}

public enum PingResultErrorDetails: Sendable, Equatable, LocalizedError {
  case noMetric
  case urlError(URLError)
  case otherError(any Error)

  //  public func hash(into hasher: inout Hasher) {
  //    hasher.combine(String(describing: self))
  //  }

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

extension PingResultDetails {
  public static let preview = PingResultDetails(
    result: nil,
    interval: 0.01
  )
}
