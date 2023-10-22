//
//  ServerPinger.swift
//
//
//  Created by Tomas Harkema on 20/10/2023.
//

import SwiftUI
import Inject
import OSLog

@Observable
public final class ServerPinger: Sendable {
  @ObservationIgnored
  private let logger = Logger(subsystem: "PlexVideo", category: "ServerPinger")

  @ObservationIgnored
  @Injected(\.serverLocator)
  private var serverLocator

  @ObservationIgnored
  private var pingerTask: Task<Void, Never>?

  @MainActor
  public private(set) var pings = [PingResult]()

  @MainActor
  public private(set) var pingsByConnection = [Connection: PingResult]()

  public init() { }

  @MainActor
  private func updatePing(ping: PingResult) {
    self.pingsByConnection[ping.connection] = ping    
    let values = self.pingsByConnection.values
    self.pings = Array(values)
  }

  private func ping(timeout: Duration = .seconds(1)) async {
    do {
      let stream = try await self.serverLocator.pingsStream(
        timeout: timeout
      )
      try Task.checkCancellation()

      for await ping in stream {
        await updatePing(ping: ping)
      }

//      await MainActor.run {
//        self.pings = stream
//        self.pingsByConnection = Dictionary(
//          stream.map { ($0.connection, $0) }
//        ) { first, second in
//          return first
//        }
//      }
    } catch is CancellationError {
      // noop
    } catch {
      assertionFailure()
      logger.error("ping error: \(error)")
    }
  }

  public func startPinging() {
    guard pingerTask == nil else {
      return
    }

    let task = Task(priority: .low) {
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(5))
        logger.info("startPinging start")
        await ping()
        logger.info("startPinging finished")
      }
      logger.info("CANCELLED?")
    }
    pingerTask = task
  }

  public func stopPinging() {
    pingerTask?.cancel()
    pingerTask = nil
  }
}
