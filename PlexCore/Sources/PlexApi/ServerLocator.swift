//
//  ServerLocator.swift
//
//
//  Created by Tomas Harkema on 09/06/2021.
//

import Foundation
import Inject
import PlexShared
import OSLog
import AsyncHelpers

enum ServerLocatorError: LocalizedError {
  case noUrl
  case noDetection
}

@Observable
public final class ServerLocator: Sendable {

  private let logger = Logger(subsystem: "PlexVideo", category: "ServerLocator")

  @ObservationIgnored
  @Injected(\.requestor)
  private var requestor

  @ObservationIgnored
  @Injected(\.serverLocatorStorageProviding)
  private var storage

  @ObservationIgnored
  @Injected(\.networkManager)
  private var networkManager

  @MainActor
  private(set) var lastTriedRootDate: Date?

  @MainActor
  private(set) var lastForceTryDate: Date?

  @MainActor
  private var isInvalidating = false

  @MainActor
  public private(set) var connection: Connection?

  @MainActor
  public private(set) var devicesLastFetch: Date?

  @MainActor
  public private(set) var servers: ServersResponse?

  @MainActor
  public private(set) var pings = [PingResult]()

  @ObservationIgnored
  fileprivate let rootEnsureOnce = EnsureOnce<HandlerLocation, Connection>()

  public init() {
    Task {
      _ = try await rootForced()
    }
  }

  private func checkLocalAndRemoteIp(
    server: Server,
    timeout: Duration
  ) async -> Result<Connection, any Error> {
    // phase 2: check if saved local and remote ip's are still viable
    do {
      guard let localConnection = await self.storage.lastUsedLocalConnection,
              let remoteConnection = await self.storage.lastUsedRemoteConnection else {
        return .failure(ServerLocatorError.noDetection)
      }

      let connection = try await selectHost(
        server: server,
        localUrl: localConnection,
        remoteUrl: remoteConnection,
        timeout: timeout
      )

      if let connection {
        await MainActor.run {
          self.connection = connection
        }
        return .success(connection)
      } else {
        return .failure(ServerLocatorError.noUrl)
      }
    } catch {
      await MainActor.run {
        storage.lastUsedLocalConnection = nil
        storage.lastUsedRemoteConnection = nil
      }

      logger.error("lastUsedLocalHost and lastUsedRemoteHost not viable... continuing! \(error)")
      return .failure(error)
    }
  }

  private func ping(
    server: Server,
    connection: Connection,
    timeout: Duration
  ) async -> PingResult {
    do {
      let uuid = UUID()
      let metricsTask = Task {
        return await self.networkManager.getMetrics(for: uuid, withTimeout: timeout)
      }

      let result = try await self.requestor.request(
        url: connection.uri,
        Root<Version>.self,
        requestUUID: uuid,
        timeout: timeout,
        invalidateAfterError: false,
        useCache: false
      )

      guard let metrics = (await metricsTask.value),
            let responseStartDate = metrics.requestStartDate,
            let responseEndDate = metrics.responseEndDate
      else {
        assertionFailure()
        return .failure(server: server, connection: connection, error: .noMetric)
      }

      let interval = responseEndDate.timeIntervalSince(responseStartDate)

      return .success(
        server: server,
        connection: connection,
        details: PingResultDetails(
          result: result,
          interval: interval,
          duration: .seconds(interval),
          measurement: .init(value: interval, unit: .seconds)
        )
      )
    } catch let error as URLError {
      logger.error("ping URL error: \(error)")
      return .failure(server: server, connection: connection, error: .urlError(error))
    } catch {
      logger.error("ping error: \(error)")
      return .failure(server: server, connection: connection, error: .otherError(error))
    }
  }

  private func selectHost(
    server: Server,
    localUrl: Connection,
    remoteUrl: Connection,
    timeout: Duration
  ) async throws -> Connection? {
    async let local = ping(
      server: server, connection: localUrl, timeout: timeout
    )
    async let remote = ping(
      server: server, connection: remoteUrl, timeout: timeout
    )

    do {
      _ = try await local.get()

      await MainActor.run {
        storage.lastUsedConnection = localUrl
      }

      return localUrl
    } catch {
      logger.error("local not succeeded \(error)")
    }

    do {
      _ = try await remote.get()

      await MainActor.run {
        storage.lastUsedConnection = remoteUrl
      }

      return remoteUrl
    } catch {
      logger.error("remote not succeeded \(error)")
      throw error
    }
  }

  nonisolated func servers() async throws -> ServersResponse {
    try await EnsureOnce.once(cacheDuration: .seconds(60 * 5)) {
      let servers = try await self.requestor.request(
        url: URL(string: "https://plex.tv/api/v2/resources")!,
        ServersResponse.self,
        queryItems: [
          URLQueryItem(name: "includeHttps", value: "1"),
          URLQueryItem(name: "includeRelay", value: "1")
        ],
        useCache: false
      )
      .filter {
        $0.provides.contains("server")
      }

      Task { @MainActor in
        self.devicesLastFetch = .now
        self.servers = servers
      }

      return servers
    }
  }

  public nonisolated func pingsStream(
    server: Server,
    connections: [Connection],
    timeout: Duration
  ) async -> AsyncStream<PingResult> {
    return AsyncStream { continuation in
      Task {
        let result = await withTaskGroup(
          of: PingResult.self, returning: [PingResult].self
        ) { group in
          for connection in connections {
            group.addTask {
              let pingResult = await self.ping(
                server: server,
                connection: connection,
                timeout: timeout
              )
              continuation.yield(pingResult)
              return pingResult
            }
          }

          let res = await group.reduce(into: [PingResult]()) { prev, current in
            prev.append(current)
          }
          return res
        }
        print(result)
        continuation.finish()
      }
    }
  }

  public nonisolated func pingsStream(
    timeout: Duration = .seconds(1)
  ) async throws -> AsyncStream<PingResult> {
    let servers = try await self.servers()
    guard let server = servers.first else {
      assertionFailure("no devices")
      throw NSError(domain: "NO DEVICES", code: 69)
    }
    return await self.pingsStream(
      server: server,
      connections: server.connections,
      timeout: timeout
    )
  }

  private nonisolated func pingsFirstResult(
    server: Server,
    connections: [Connection]
  ) async throws -> PingSuccess? {
    let results = await pingsStream(
      server: server,
      connections: connections,
      timeout: .seconds(1)
    )
    return await results.compactMap { res in
      do {
        guard res.server == server else {
          return nil
        }
        let result = try res.get()
        return result
      } catch {
        self.logger.error("ping first result error: \(error)")
        return nil
      }
    }.first {
      $0.server == server
    }
  }

  private nonisolated func chooseServer() async throws -> Connection? {
    let servers = try await servers()
    guard let server = servers.first else {
      assertionFailure("no devices")
      throw NSError(domain: "NO DEVICES", code: 69)
    }
    let connections = server.connections.filter { $0.protocol == "https" }

    let serversGroupedByLocal = Dictionary(grouping: connections, by: {
      $0.local
    })

    async let localPings = pingsFirstResult(
      server: server,
      connections: serversGroupedByLocal[true] ?? []
    )
    async let remotePings = pingsFirstResult(
      server: server,
      connections: serversGroupedByLocal[false] ?? []
    )

    let choice: Connection?

    if let local = try? await localPings {
      choice = local.connection
    } else if let remote = try await remotePings {
      choice = remote.connection
    } else {
      choice = nil
    }

    await MainActor.run {
      self.connection = choice
      storage.lastUsedConnection = choice
    }

    let local = try? await localPings
    let remote = try? await remotePings

    await MainActor.run {
      storage.lastUsedLocalConnection = local?.connection
      storage.lastUsedRemoteConnection = remote?.connection
    }

    return choice
  }

  @MainActor
  func invalidate() async {

    if isInvalidating {
      return
    }

    isInvalidating = true
    defer {
      isInvalidating = false
    }

//    lastConfirmedUrl = nil
    storage.lastUsedConnection = nil
    self.connection = nil

    do {
      _ = try await root(force: true)
    } catch {
      logger.error("invalidate error: \(error)")
    }
  }
}

extension ServerLocator {

  private func rootForced() async throws -> Connection {
    return try await EnsureOnce.once {
      guard let connection = try await self.chooseServer() else {
        throw ServerLocatorError.noUrl
      }
      await MainActor.run {
        self.lastForceTryDate = Date()
      }
      return connection
    }
  }

  public func root(
    force: Bool = false
  ) async throws -> Connection {
    if force {
      await rootEnsureOnce.cancel()
      return try await rootForced()
    }

    if let connection = await connection {
      return connection
    }

    return try await rootEnsureOnce.once {
      let servers = try await self.servers()

      guard let server = servers.first else {
        throw NSError(domain: "derp", code: 69)
      }

      // phase 1: check for last used root and if its still viable...
      do {
        if let lastUsedConnection = await self.storage.lastUsedConnection {
          if await self.lastTriedRootDate == nil {
            let pingResult = try await self.ping(
              server: server,
              connection: lastUsedConnection,
              timeout: .seconds(1)
            ).get()
            self.logger.info("phase 1 \(String(describing: pingResult))")
            await MainActor.run {
              self.lastTriedRootDate = Date()
            }
          }
          await MainActor.run {
            self.connection = lastUsedConnection
          }
          return lastUsedConnection
        }
      } catch {
        await MainActor.run {
          self.storage.lastUsedConnection = nil
        }
        self.logger.error("lastUsedRoot not viable... continuing! \(error)")
      }

      do {
        return try await self.checkLocalAndRemoteIp(server: server, timeout: .seconds(5)).get()
      } catch {
        self.logger.error("secondPhase not viable... continuing! \(error)")
      }

      // phase 3: refetch potential servers to connect to
      guard let url = try await self.chooseServer() else {
        throw ServerLocatorError.noUrl
      }
      return url
    }
  }
}


@MainActor
public protocol ServerLocatorStorageProviding: AnyObject {
  var lastUsedConnection: Connection? { get set }
  var lastUsedLocalConnection: Connection? { get set }
  var lastUsedRemoteConnection: Connection? { get set }
}

public extension InjectedValues {
  var serverLocatorStorageProviding: any ServerLocatorStorageProviding {
    get { Self[ServerLocatorStorageProvidingKey.self] }
    set { Self[ServerLocatorStorageProvidingKey.self] = newValue }
  }
}

public struct ServerLocatorStorageProvidingKey: InjectionKey {
  public static var currentValue: (any ServerLocatorStorageProviding)?
}

public extension InjectedValues {
  var serverLocator: ServerLocator {
    get { Self[ServerLocatorKey.self] }
    set { Self[ServerLocatorKey.self] = newValue }
  }
}

private struct ServerLocatorKey: InjectionKey {
  static var currentValue: ServerLocator? = .init()
}
