//
//  ServerLocator.swift
//
//
//  Created by Tomas Harkema on 09/06/2021.
//

import AsyncHelpers
import Foundation
import Inject
import OSLog
import PlexShared

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
  public private(set) var connection: ServerWithCurrentConnection?

  @MainActor
  public private(set) var devicesLastFetch: Date?

  @MainActor
  public private(set) var servers: ServersResponse?

  //  @MainActor
  //  public private(set) var pings = [PingResult]()

  @ObservationIgnored
  fileprivate let rootEnsureOnce = EnsureOnce<HandlerLocation, ServerWithCurrentConnection>()

  public init() {
    Task(priority: .low) {
      _ = try await root()
      _ = try await rootForced()
    }
  }

  private func checkLocalAndRemoteIp(
    server: Server,
    timeout: Duration
  ) async -> Result<ServerWithCurrentConnection, any Error> {
    // phase 2: check if saved local and remote ip's are still viable
    do {
      guard let localConnection = await storage.lastUsedLocalConnection,
        let remoteConnection = await storage.lastUsedRemoteConnection
      else {
        return .failure(ServerLocatorError.noDetection)
      }

      let connection = try await selectHost(
        server: server,
        localUrl: localConnection.connection,
        remoteUrl: remoteConnection.connection,
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
    server: ServerWithConnection,
    timeout: Duration
  ) async -> PingResult {
    do {
      let uuid = UUID()
      let metricsTask = Task {
        await self.networkManager.getMetrics(for: uuid, withTimeout: timeout)
      }

      let result = try await requestor.request(
        url: server.connection.uri,
        Root<Capabilities>.self,
        requestUUID: uuid,
        timeout: timeout,
        invalidateAfterError: false,
        useCache: false
      )

      guard let metrics = await (metricsTask.value),
        let responseStartDate = metrics.requestStartDate,
        let responseEndDate = metrics.responseEndDate
      else {
        assertionFailure()
        return .failure(serverWithConnection: server, error: .noMetric)
      }

      let interval = responseEndDate.timeIntervalSince(responseStartDate)

      return .success(
        serverWithConnection: server,
        details: PingResultDetails(
          result: result,
          interval: interval
        )
      )
    } catch let error as URLError {
      //      logger.error("ping URL error: \(error)")
      logger.error("ping URL error: \(server.server.name) \(server.connection.address)")
      return .failure(serverWithConnection: server, error: .urlError(error))
    } catch {
      //      logger.error("ping error: \(error)")
      logger.error("ping error: \(server.server.name) \(server.connection.address)")
      return .failure(serverWithConnection: server, error: .otherError(error))
    }
  }

  private func selectHost(
    server: Server,
    localUrl: Connection,
    remoteUrl: Connection,
    timeout: Duration
  ) async throws -> ServerWithCurrentConnection? {
    async let local = ping(
      server: ServerWithConnection(server: server, connection: localUrl),
      timeout: timeout
    )
    async let remote = ping(
      server: ServerWithConnection(server: server, connection: remoteUrl),
      timeout: timeout
    )

    let localConnection = ServerWithCurrentConnection(server: server, connection: localUrl)
    do {
      _ = try await local.get()
      await MainActor.run {
        storage.lastUsedConnection = localConnection
      }

      return localConnection
    } catch {
      logger.error("local not succeeded \(error)")
    }

    let remoteConnection = ServerWithCurrentConnection(server: server, connection: remoteUrl)
    do {
      _ = try await remote.get()

      await MainActor.run {
        storage.lastUsedConnection = remoteConnection
      }

      return remoteConnection
    } catch {
      logger.error("remote not succeeded \(error)")
      throw error
    }
  }

  nonisolated func servers() async throws -> ServersResponse {
    try await EnsureOnce.once(cacheDuration: .seconds(60 * 5)) {
      let servers: [Server] = try await self.requestor.request(
        url: URL(string: "https://plex.tv/api/v2/resources")!,
        [Server].self,
        queryItems: [
          URLQueryItem(name: "includeHttps", value: "1"),
          URLQueryItem(name: "includeRelay", value: "1"),
        ],
        useCache: false
      )
      .filter {
        $0.provides.contains("server")
      }

      let response: ServersResponse = try await withThrowingTaskGroup(
        of: ServerAndCapabilities.self,
        returning: ServersResponse.self
      ) { group in
        for server in servers {
          group.addTask {
            do {
              guard
                let ping = try await self.pingsFirstResult(
                  server: server,
                  connections: server.connections
                )
              else {
                throw NSError(domain: "null error", code: 69)
              }

              let caps: Result<Root<Capabilities>, any Error> =
                if let result = ping.details.result {
                  .success(result)
                } else {
                  .failure(NSError(domain: "null error", code: 69))
                }
              return ServerAndCapabilities(
                server: ping.serverWithConnection,
                capabilities: caps
              )
            } catch {
              throw error
              //              return
              //                ServerAndCapabilities(
              //                  server: server,
              //                  capabilities: .failure(error)
              //                )
            }
          }
        }

        return try await group.reduce(into: .init()) { prev, curr in
          prev.append(curr)
        }
      }

      Task { @MainActor in
        self.devicesLastFetch = .now
        self.servers = response
      }

      return response
    }
  }

  public nonisolated func pingsStream(
    server: Server,
    connections: [Connection],
    timeout: Duration
  ) async -> AsyncStream<PingResult> {
    AsyncStream { continuation in
      Task {
        let result = await withTaskGroup(
          of: PingResult.self,
          returning: [PingResult].self
        ) { group in
          for connection in connections {
            group.addTask {
              let pingResult = await self.ping(
                server: ServerWithConnection(server: server, connection: connection),
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
        continuation.finish()
      }
    }
  }

  public nonisolated func pingsStream(
    timeout: Duration = .seconds(1)
  ) async throws -> AsyncStream<PingResult> {
    let servers = try await servers()
    guard let server = servers.first?.server else {
      assertionFailure("no devices")
      throw NSError(domain: "NO DEVICES", code: 69)
    }
    return await pingsStream(
      server: server.server,
      connections: server.server.connections,
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
        guard res.serverWithConnection.server == server else {
          return nil
        }
        let result = try res.get()
        return result
      } catch {
        self.logger.error("ping first result error: \(error)")
        return nil
      }
    }.first {
      $0.serverWithConnection.server == server
    }
  }

  private nonisolated func chooseServer() async throws -> ServerWithCurrentConnection? {
    let servers = try await servers()
    guard let server = servers.first else {
      assertionFailure("no devices")
      throw NSError(domain: "NO DEVICES", code: 69)
    }
    let connections = server.server.server.connections.filter {
      $0.protocol == "https"
    }

    let serversGroupedByLocal = Dictionary(
      grouping: connections,
      by: {
        $0.local
      }
    )

    async let localPings = pingsFirstResult(
      server: server.server.server,
      connections: serversGroupedByLocal[true] ?? []
    )
    async let remotePings = pingsFirstResult(
      server: server.server.server,
      connections: serversGroupedByLocal[false] ?? []
    )

    let choice: ServerWithCurrentConnection? =
      if let local = try? await localPings {
        ServerWithCurrentConnection(
          server: local.serverWithConnection.server,
          connection: local.serverWithConnection.connection
        )
      } else if let remote = try await remotePings {
        ServerWithCurrentConnection(
          server: remote.serverWithConnection.server,
          connection: remote.serverWithConnection.connection
        )
      } else {
        nil
      }

    await MainActor.run {
      self.connection = choice
      storage.lastUsedConnection = choice
    }

    let local = (try? await localPings).map {
      ServerWithCurrentConnection(
        server: $0.serverWithConnection.server,
        connection: $0.serverWithConnection.connection
      )
    }
    let remote = (try? await remotePings).map {
      ServerWithCurrentConnection(
        server: $0.serverWithConnection.server,
        connection: $0.serverWithConnection.connection
      )
    }

    await MainActor.run {
      storage.lastUsedLocalConnection = local
      storage.lastUsedRemoteConnection = remote
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

    storage.lastUsedConnection = nil
    connection = nil

    do {
      _ = try await root(force: true)
    } catch {
      logger.error("invalidate error: \(error)")
    }
  }
}

extension ServerLocator {
  private func rootForced() async throws -> ServerWithCurrentConnection {
    try await EnsureOnce.once {
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
  ) async throws -> ServerWithCurrentConnection {
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
              server: ServerWithConnection(
                server: lastUsedConnection.server,
                connection: lastUsedConnection.connection
              ),
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
        let res = try await self.checkLocalAndRemoteIp(
          server: server.server.server,
          timeout: .seconds(5)
        )
        .get()
        return res
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
  var lastUsedConnection: ServerWithCurrentConnection? { get set }
  var lastUsedLocalConnection: ServerWithCurrentConnection? { get set }
  var lastUsedRemoteConnection: ServerWithCurrentConnection? { get set }
}

extension InjectedValues {
  public var serverLocatorStorageProviding: any ServerLocatorStorageProviding {
    get { Self[ServerLocatorStorageProvidingKey.self] }
    set { Self[ServerLocatorStorageProvidingKey.self] = newValue }
  }
}

public struct ServerLocatorStorageProvidingKey: InjectionKey {
  public static var currentValue: (any ServerLocatorStorageProviding)?
}

extension InjectedValues {
  public var serverLocator: ServerLocator {
    get { Self[ServerLocatorKey.self] }
    set { Self[ServerLocatorKey.self] = newValue }
  }
}

private struct ServerLocatorKey: InjectionKey {
  static var currentValue: ServerLocator? = .init()
}
