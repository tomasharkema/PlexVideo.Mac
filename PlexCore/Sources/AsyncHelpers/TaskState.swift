//
//  TaskState.swift
//  
//
//  Created by Tomas Harkema on 21/10/2023.
//

import Foundation

public enum TaskStateResult<ResultType: Sendable>: Sendable {
  case idle
  case running
  case cancelled
  case result(ResultType, Date)
  case error(any Error)

  public var isFinished: Bool {
    switch self {
    case .idle, .running:
      return false

    case .cancelled, .result, .error:
      return true
      
    }
  }
}

public actor TaskState<ResultType: Sendable>: Sendable {
  private let handler: @Sendable () async throws -> ResultType
  private lazy var task: Task<ResultType, any Error> = {
    Task {
      return try await self.run(handler)
    }
  }()
  public private(set) var state = TaskStateResult<ResultType>.idle
//  public private(set) var started: Date?
//  public private(set) var finished: Date?

  public init(
    _ handler: @Sendable @escaping () async throws -> ResultType
  ) {
    self.handler = handler
    Task {
      _ = await self.task
    }
  }

  private func run(
    _ handler: @Sendable @escaping () async throws -> ResultType
  ) async throws -> ResultType {
    self.state = .running

    do {
      let result = try await handler()
      try Task.checkCancellation()
      self.state = .result(result, Date())
      return result
    } catch let error as CancellationError {
      self.state = .cancelled
      throw error
    } catch {
      self.state = .error(error)
      throw error
    }
  }

  public var value: ResultType {
    get async throws {
      try await task.value
    }
  }

  public func cancel() {
    task.cancel()
  }
}
