//
//  PingResult.swift
//
//
//  Created by Tomas Harkema on 19/10/2023.
//

import AsyncHelpers
import Foundation
import PlexShared
import SwiftStacktrace

public struct PingResult {
  public let serverWithConnection: ServerWithConnection
  public let details: Result<PingResultDetails, PingResultError>

  package init(
    serverWithConnection: ServerWithConnection,
    details: Result<PingResultDetails, PingResultError>
  ) {
    self.serverWithConnection = serverWithConnection
    self.details = details
  }
}

extension PingResult: Sendable, Equatable {}

extension PingResult: Identifiable {
  public var id: Connection.ID {
    serverWithConnection.connection.id
  }
}

public struct PingSuccess: Sendable, Equatable {
  public let serverWithConnection: ServerWithConnection
  public let details: PingResultDetails
}

extension PingSuccess: Identifiable {
  public var id: Connection.ID {
    serverWithConnection.connection.id
  }
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
    error: PingResultErrorDetails,
    stacktraceError: StacktraceError
  ) -> PingResult {
    PingResult(
      serverWithConnection: serverWithConnection,
      details: .failure(
        PingResultError(
          serverWithConnection: serverWithConnection,
          details: error,
          stacktraceError: stacktraceError
        )
      )
    )
  }
}

extension PingResult {
  public var result: Result<PingSuccess, PingResultError> {
    switch details {
    case .success(let details):
      .success(
        PingSuccess(
          serverWithConnection: serverWithConnection,
          details: details
        )
      )

    case .failure(let error):
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

public struct PingResultError: Sendable, Equatable, LocalizedError, StacktraceErrorContainable {
  public let serverWithConnection: ServerWithConnection
  public let details: PingResultErrorDetails

  @AsyncHelpers.EquatableNoop
  public var stacktraceError: StacktraceError?

  package init(
    serverWithConnection: ServerWithConnection,
    details: PingResultErrorDetails,
    stacktraceError: StacktraceError
  ) {
    self.serverWithConnection = serverWithConnection
    self.details = details
    self.stacktraceError = stacktraceError
  }

  public var errorDescription: String? {
    details.errorDescription
  }
}

public enum PingResultErrorDetails: Sendable, Equatable, LocalizedError,
  StacktraceErrorContainable
{
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

    case .urlError(let urlError):
      urlError.localizedDescription

    case .otherError(let anyError):
      anyError.localizedDescription
    }
  }

  public var stacktraceError: StacktraceError? {
    switch self {
    case .noMetric:
      nil
    case .otherError(let error as StacktraceError):
      error
    case .otherError(let error):
      nil
    case .urlError:
      nil
    }
  }
}

extension PingResultDetails {
  public static let preview = PingResultDetails(
    result: nil,
    interval: 0.01
  )
}
