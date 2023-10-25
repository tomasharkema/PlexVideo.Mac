//
//  EnsureOnce.swift
//
//
//  Created by Tomas Harkema on 21/10/2023.
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "PlexVideo", category: "EnsureOnce")

public actor EnsureOnce<IdentifierType: Hashable & Sendable, ResultType: Sendable>: Sendable {
  private let initLocation: HandlerLocation
  private var handlers = [IdentifierType: StoredTask<IdentifierType, ResultType>]()

  public init(
    file: String = #file,
    line: UInt = #line,
    function: String = #function
  ) {
    self.init(location: HandlerLocation(file: file, line: line, function: function))
  }

  init(
    location: HandlerLocation
  ) {
    initLocation = location
  }

  public static func once(
    id: IdentifierType,
    cacheDuration: Duration? = nil,
    _ handler: @Sendable @escaping () async throws -> ResultType,
    file: String = #file,
    line: UInt = #line,
    function: String = #function
  ) async throws -> ResultType {
    try await once(
      id: id,
      cacheDuration: cacheDuration,
      handler,
      location: HandlerLocation(
        file: file,
        line: line,
        function: function
      )
    )
  }

  private static func once(
    id: IdentifierType,
    cacheDuration: Duration?,
    _ handler: @Sendable @escaping () async throws -> ResultType,
    location: HandlerLocation
  ) async throws -> ResultType {
    if let idLocation = id as? HandlerLocation {
      precondition(idLocation == location)
    }
    let result = try await StaticStorage.shared.get(location: location)
      .once(id: id.hashValue, cacheDuration: cacheDuration, handler, location: location)
    // swiftlint:disable:next force_cast
    return result as! ResultType
  }

  public static func once(
    cacheDuration: Duration? = nil,
    _ handler: @Sendable @escaping () async throws -> ResultType,
    file: String = #file,
    line: UInt = #line,
    function: String = #function
  ) async throws -> ResultType where IdentifierType == HandlerLocation {
    let location = HandlerLocation(file: file, line: line, function: function)
    return try await once(id: location, cacheDuration: cacheDuration, handler, location: location)
  }

  /// this variant allows only one location for once to be called.
  public func once(
    cacheDuration: Duration? = nil,
    _ handler: @Sendable @escaping () async throws -> ResultType,
    file _: String = #file,
    line _: UInt = #line,
    function _: String = #function
  ) async throws -> ResultType where IdentifierType == HandlerLocation {
    try await once(id: initLocation, cacheDuration: cacheDuration, handler, location: initLocation)
  }

  private func once(
    id: IdentifierType,
    cacheDuration: Duration?,
    _ handler: @Sendable @escaping () async throws -> ResultType,
    location: HandlerLocation
  ) async throws -> ResultType {
    if let cacheDuration {
      logger.info("cacheDuration: \(cacheDuration)")
    }
    if let existingHandler = handlers[id] {
      let state = await existingHandler.task.state
      let task = existingHandler.task

      let res = handleExistingResult(
        id: id,
        task: task,
        state: state,
        cacheDuration: cacheDuration
      )

      switch res {
      case .returnCached:
        return try await existingHandler.task.value

      case .stale:
        handlers.removeValue(forKey: id)
      }
    }

    let task = Task {
      do {
        logger.info("EXCUTE FOR: handlerLocation \(String(describing: location))")
        return try await handler()
      } catch {
        throw error
      }
    }

    handlers[id] = StoredTask(
      identifier: id,
      task: TaskState {
        try await task.value
      },
      storeDate: .now
    )

    do {
      let result = try await task.value
      return result
    } catch {
      throw error
    }
  }

  public func once(
    id: IdentifierType,
    cacheDuration: Duration? = nil,
    _ handler: @Sendable @escaping () async throws -> ResultType,
    file: String = #file,
    line: UInt = #line,
    function: String = #function
  ) async throws -> ResultType {
    try await once(
      id: id,
      cacheDuration: cacheDuration,
      handler,
      location: HandlerLocation(file: file, line: line, function: function)
    )
  }

  public func cancel(id: IdentifierType) async {
    await handlers[id]?.task.cancel()
    handlers.removeValue(forKey: id)
  }

  public func cancel() async where IdentifierType == HandlerLocation {
    await handlers[initLocation]?.task.cancel()
    handlers.removeValue(forKey: initLocation)
  }

  deinit {
    if !handlers.isEmpty {
      assertionFailure("HANDLERS NOT DONE!")
    }
    logger.info("DEINIT")
  }
}

extension EnsureOnce {
  enum HandleExistingResult {
    case stale
    case returnCached
  }

  private func handleExistingResult(
    id _: IdentifierType,
    task _: TaskState<ResultType>,
    state: TaskStateResult<ResultType>,
    cacheDuration: Duration?
  ) -> HandleExistingResult {
    switch (cacheDuration, state) {
    case let (.some(duration), .result(result, date)):
      let timeInterval = abs(date.timeIntervalSinceNow)
      if timeInterval < Double(duration.components.seconds) {
        return .returnCached
      } else {
        return .stale
      }

    case (.some, .cancelled), (.some, .error):
      return .stale

    case (.none, .cancelled), (.none, .result), (.none, .error):
      return .stale

    case (_, .idle), (_, .running):
      return .returnCached
    }
  }
}
