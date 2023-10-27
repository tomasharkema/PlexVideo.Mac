//
//  ServerLocator.swift
//
//
//  Created by Tomas Harkema on 09/06/2021.
//

import AsyncAlgorithms
import AsyncHelpers
import Dependencies
import Foundation
import OSLog
import PlexShared

enum ServerLocatorError: LocalizedError {
  case noUrl
  case noDetection
}

@Observable
public final class ServerLocator: Sendable {
  private let logger = Logger(subsystem: "PlexVideo", category: "ServerLocator")

//  private let resources = ResourcesService()

  @ObservationIgnored
  @Dependency(\.resourcesService)
  private var resources

  @ObservationIgnored
  @Dependency(\.requestor)
  private var requestor

  @ObservationIgnored
  @Dependency(\.serverLocatorStorageProviding)
  private var storage

  @ObservationIgnored
  @Dependency(\.networkManager)
  private var networkManager

  @MainActor
  private(set) var lastTriedRootDate: Date?

  @MainActor
  private(set) var lastForceTryDate: Date?

  @MainActor
  private var isInvalidating = false

  @MainActor
  public private(set) var connection = [Server.ID: ServerWithCurrentConnection]()

  @MainActor
  public private(set) var devicesLastFetch: Date?

  @MainActor
  public private(set) var servers: ServersResponse?

  //  @MainActor
  //  public private(set) var pings = [PingResult]()

  @ObservationIgnored
  fileprivate let rootEnsureOnce = EnsureOnce<Server.ID, ServerWithCurrentConnection>()

  public init() {
    Task(priority: .low) {
      _ = try await getServersForced()
    }
    Task(priority: .low) {
      _ = try await rootForAll()
      _ = try await rootForcedForAll()
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
        localUrl: localConnection.value.connection,
        remoteUrl: remoteConnection.value.connection,
        timeout: timeout
      )

      if let connection {
        await MainActor.run {
          var new = self.connection
          new[server.id] = connection
          self.connection = new
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

  private func selectHost(
    server: Server,
    localUrl: Connection,
    remoteUrl: Connection,
    timeout: Duration
  ) async throws -> ServerWithCurrentConnection? {
    async let local = resources.ping(
      server: ServerWithConnection(server: server, connection: localUrl),
      timeout: timeout
    )
    async let remote = resources.ping(
      server: ServerWithConnection(server: server, connection: remoteUrl),
      timeout: timeout
    )

    let localConnection = ServerWithCurrentConnection(server: server, connection: localUrl)
    do {
      _ = try await local.get()
      await MainActor.run {
        storage.lastUsedConnection = CodableWrapper(value: localConnection)
      }

      return localConnection
    } catch {
      logger.error("local not succeeded \(error)")
    }

    let remoteConnection = ServerWithCurrentConnection(server: server, connection: remoteUrl)
    do {
      _ = try await remote.get()

      await MainActor.run {
        storage.lastUsedConnection = CodableWrapper(value: remoteConnection)
      }

      return remoteConnection
    } catch {
      logger.error("remote not succeeded \(error)")
      throw error
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
              let pingResult = await self.resources.ping(
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
  ) async throws -> AsyncJoinedSequence<AsyncSyncSequence<[AsyncStream<PingResult>]>> {
    let servers = try await getServers()

    let streams = await withTaskGroup(
      of: AsyncStream<PingResult>.self,
      returning: [AsyncStream<PingResult>].self
    ) { group in
      for server in servers {
        group.addTask {
          await self.pingsStream(
            server: server.server,
            connections: server.server.connections,
            timeout: timeout
          )
        }
      }

      return await group.reduce(into: .init()) { prev, curr in
        prev.append(curr)
      }
    }
    let joined = streams.async.joined()
    return joined
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

  private nonisolated func chooseServer(
    server: Server
  ) async throws -> ServerWithCurrentConnection? {
    let connections = server.connections.filter {
      $0.protocol == "https"
    }

    let serversGroupedByLocal = Dictionary(
      grouping: connections,
      by: {
        $0.local
      }
    )

    async let localPings = pingsFirstResult(
      server: server,
      connections: serversGroupedByLocal[true] ?? []
    )
    async let remotePings = pingsFirstResult(
      server: server,
      connections: serversGroupedByLocal[false] ?? []
    )

    let choice: ServerWithCurrentConnection? =
      if let local = try? await localPings
    {
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
      var new = self.connection
      new[server.id] = choice
      self.connection = new

      storage.lastUsedConnection = choice.map { CodableWrapper(value: $0) }
    }

    let local = await (try? localPings).map {
      ServerWithCurrentConnection(
        server: $0.serverWithConnection.server,
        connection: $0.serverWithConnection.connection
      )
    }
    let remote = await (try? remotePings).map {
      ServerWithCurrentConnection(
        server: $0.serverWithConnection.server,
        connection: $0.serverWithConnection.connection
      )
    }

    await MainActor.run {
      storage.lastUsedLocalConnection = local.map { CodableWrapper(value: $0) }
      storage.lastUsedRemoteConnection = remote.map { CodableWrapper(value: $0) }
    }

    return choice
  }

  func invalidate() async {
    assertionFailure()
  }

  @MainActor
  func invalidate(server: Server) async {
    if isInvalidating {
      return
    }

    isInvalidating = true
    defer {
      isInvalidating = false
    }

    storage.lastUsedConnection = nil
    connection.removeValue(forKey: server.id)

    do {
      _ = try await root(server: server, force: true)
    } catch {
      logger.error("invalidate error: \(error)")
    }
  }
}

extension ServerLocator {
  private func rootForcedForAll() async throws {
    let servers = try await getServers()

    await withDiscardingTaskGroup { group in
      for server in servers {
        group.addTask {
          do {
            try await self.rootForced(server: server.server)
          } catch {
            self.logger.error("rootForcedForAll error: \(error)")
          }
        }
      }
    }
  }

  private func rootForced(server: Server) async throws -> ServerWithCurrentConnection {
    try await EnsureOnce.once {
      guard let connection = try await self.chooseServer(server: server) else {
        throw ServerLocatorError.noUrl
      }
      await MainActor.run {
        self.lastForceTryDate = Date()
      }
      return connection
    }
  }

  private func rootForAll() async throws {
    let servers = try await getServers()

    await withDiscardingTaskGroup { group in
      for server in servers {
        group.addTask {
          do {
            try await self.root(server: server.server)
          } catch {
            self.logger.error("rootForAll error: \(error)")
          }
        }
      }
    }
  }

  public func getServers() async throws -> ServersResponse {
    let localServers = await servers
    let storedServers = await storage.servers?.value

    if localServers == nil, let storedServers {
      await MainActor.run {
        self.servers = storedServers.map {
          ServerAndCapabilities(server: $0, capabilities: .failure(NullError()))
        }
      }
    }

    if let servers = await servers {
      return servers
    }

    return try await getServersForced()
  }

  private func getServersForced() async throws -> [ServerAndCapabilities] {
    try await EnsureOnce.once {
      let servers = try await self.resources.servers()
      Task { @MainActor in
        self.servers = servers
        self.storage.servers = CodableWrapper(value: servers.map(\.server))
      }
      return servers
    }
  }

  public func root(
    server: Server,
    force: Bool = false
  ) async throws -> ServerWithCurrentConnection {
    if force {
      await rootEnsureOnce.cancel(id: server.id)
      return try await rootForced(server: server)
    }

    if let connection = await connection[server.id] {
      return connection
    }

    return try await rootEnsureOnce.once(id: server.id) {
      let servers = try await self.getServers()

      guard let server = servers.first else {
        throw NSError(domain: "derp", code: 69)
      }

      // phase 1: check for last used root and if its still viable...
      do {
        if let lastUsedConnection = await self.storage.lastUsedConnection {
          if await self.lastTriedRootDate == nil {
            let pingResult = try await self.resources.ping(
              server: ServerWithConnection(
                server: lastUsedConnection.value.server,
                connection: lastUsedConnection.value.connection
              ),
              timeout: .seconds(1)
            ).get()
            self.logger.info("phase 1 \(String(describing: pingResult))")
            await MainActor.run {
              self.lastTriedRootDate = Date()
            }
          }
          await MainActor.run {
            var new = self.connection
            new[server.id] = lastUsedConnection.value
            self.connection = new
          }
          return lastUsedConnection.value
        }
      } catch {
        await MainActor.run {
          self.storage.lastUsedConnection = nil
        }
        self.logger.error("lastUsedRoot not viable... continuing! \(error)")
      }

      do {
        let res = try await self.checkLocalAndRemoteIp(
          server: server.server,
          timeout: .seconds(5)
        )
        .get()
        return res
      } catch {
        self.logger.error("secondPhase not viable... continuing! \(error)")
      }

      // phase 3: refetch potential servers to connect to
      guard let url = try await self.chooseServer(server: server.server) else {
        throw ServerLocatorError.noUrl
      }
      return url
    }
  }
}

@MainActor
public protocol ServerLocatorStorageProviding: AnyObject {
  var lastUsedConnection: CodableWrapper<ServerWithCurrentConnection>? { get set }
  var lastUsedLocalConnection: CodableWrapper<ServerWithCurrentConnection>? { get set }
  var lastUsedRemoteConnection: CodableWrapper<ServerWithCurrentConnection>? { get set }
  var servers: CodableWrapper<[Server]>? { get set }
}

public extension DependencyValues {
  var serverLocatorStorageProviding: any ServerLocatorStorageProviding {
    get { self[ServerLocatorStorageProvidingKey.self] }
    set { self[ServerLocatorStorageProvidingKey.self] = newValue }
  }
}

public struct ServerLocatorStorageProvidingKey: TestDependencyKey {
  public static var testValue: (any ServerLocatorStorageProviding) =
    unimplemented() //: (any ServerLocatorStorageProviding)?
}

public extension DependencyValues {
  var serverLocator: ServerLocator {
    get { self[ServerLocatorKey.self] }
    set { self[ServerLocatorKey.self] = newValue }
  }
}

private struct ServerLocatorKey: DependencyKey {
  static var liveValue: ServerLocator = .init()
}
