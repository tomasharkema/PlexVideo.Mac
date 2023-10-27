//
//  ServerPinger.swift
//
//
//  Created by Tomas Harkema on 20/10/2023.
//

import Dependencies
import OSLog
import PlexShared
import Processed
import SwiftUI

public struct PingerState {
  public var results: [ServerWithConnection.ID: PingResult]
  public var lastRun: Date
}

@MainActor
@Observable
public final class ServerPinger: Sendable, LoadableSupport {
  @ObservationIgnored
  private let logger = Logger(subsystem: "PlexVideo", category: "ServerPinger")

  @ObservationIgnored
  @Dependency(\.serverLocator)
  private var serverLocator

  public private(set) var state: LoadableState<PingerState> = .absent

  public init() {
    startPinging()
  }

  private func updatePing(ping: PingResult, yield: (PingerState) -> Void) {
    var updated = state.data ?? PingerState(results: [:], lastRun: .now)
    updated.results[ping.serverWithConnection.id] = ping
    yield(updated)
  }

  private func ping(timeout: Duration = .seconds(1), yield: (PingerState) -> Void) async {
    do {
      let stream = try await serverLocator.pingsStream(
        timeout: timeout
      )
      try Task.checkCancellation()

      var updated = state.data ?? PingerState(results: [:], lastRun: .now)
      updated.lastRun = .now
      yield(updated)

      for await ping in stream {
        updatePing(ping: ping, yield: yield)
      }
    } catch is CancellationError {
      // noop
    } catch {
      logger.error("ping error: \(error)")
    }
  }

  private func startPinging() {
    load(\.state, priority: .low) { yield in
      while !Task.isCancelled {
        self.logger.info("startPinging start")
        await self.ping { value in
          yield(.loaded(value))
        }
        self.logger.info("startPinging finished")
        try? await Task.sleep(for: .seconds(10))
      }
      self.logger.info("CANCELLED?")
    }
  }

//  public func stopPinging() {
//    cancel(\.state)
  //    pingerTask?.cancel()
  //    pingerTask = nil
//  }
}

public extension DependencyValues {
  var serverPinger: ServerPinger {
    get { self[ServerPingerKey.self] }
    set { self[ServerPingerKey.self] = newValue }
  }
}

private struct ServerPingerKey: DependencyKey {
  @MainActor
  static var liveValue: ServerPinger = .init()
}
