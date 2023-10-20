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
import PlexShared

enum ServerLocatorError: LocalizedError {
  case noUrl
  case noDetection
}

@MainActor
public final class ServerLocator: ObservableObject {

  private let logger = Logger(subsystem: "PlexVideo", category: "ServerLocator")

  @Injected(\.requestor)
  private var requestor

  @Injected(\.serverLocatorStorageProviding)
  private var storage

  private(set) var lastTriedRootDate: Date?
  private(set) var lastForceTryDate: Date?
//  private(set) var lastConfirmedUrl: URL?

  private var rootTask: Task<Connection, any Error>?
  private var rootForcedTask: Task<Connection, any Error>?
//  private var pingingTask: Task<(Root<Version>, TimeInterval), any Error>?
  private var isInvalidating = false

  @Published
  public private(set) var connection: Connection?

  @Published
  public private(set) var devices = [DeviceResponse]()

  @Published
  public private(set) var pings = [PingResult]()

  public nonisolated init() {
    Task {
//      _ = try await devices()
      _ = try await rootForced()
    }
  }

  public func rootForced() async throws -> Connection {

    if let rootForcedTask {
      return try await rootForcedTask.value
    }

    defer {
      rootForcedTask = nil
    }

    let task = Task {
      guard let connection = try await chooseServer() else {
        throw ServerLocatorError.noUrl
      }
      lastForceTryDate = Date()
      return connection
    }

    rootForcedTask = task

    return try await task.value
  }

  private func checkLocalAndRemoteIp() async throws -> Result<Connection, any Error> {
    // phase 2: check if saved local and remote ip's are still viable
    do {
      guard let localConnection = self.storage.lastUsedLocalConnection, 
              let remoteConnection = self.storage.lastUsedRemoteConnection else {
        return .failure(ServerLocatorError.noDetection)
      }

      let connection = try await selectHost(
        localUrl: localConnection,
        remoteUrl: remoteConnection
      )

      if let connection {
        self.connection = connection
        return .success(connection)
      } else {
        return .failure(ServerLocatorError.noUrl)
      }
    } catch {
      storage.lastUsedLocalConnection = nil
      storage.lastUsedRemoteConnection = nil

      logger.error("lastUsedLocalHost and lastUsedRemoteHost not viable... continuing! \(error)")
      return .failure(error)
    }
  }

  public func root(force: Bool = false) async throws -> Connection {
    if force {
      rootTask?.cancel()
      rootTask = nil
      return try await rootForced()
    }

    if let connection {
      return connection
    }

    if let rootTask {
      return try await rootTask.value
    }

    defer {
      rootTask = nil
    }

    let task = Task {
      // phase 1: check for last used root and if its still viable...
      do {
        if let lastUsedConnection = storage.lastUsedConnection {
          if lastTriedRootDate == nil {
            _ = try await ping(server: lastUsedConnection.uri)
            lastTriedRootDate = Date()
          }
          self.connection = lastUsedConnection
          return lastUsedConnection
        }
      } catch {
        storage.lastUsedConnection = nil
        logger.error("lastUsedRoot not viable... continuing! \(error)")
      }

      do {
        return try await self.checkLocalAndRemoteIp().get()
      } catch {
        logger.error("secondPhase not viable... continuing! \(error)")
      }

      // phase 3: refetch potential servers to connect to
      guard let url = try await chooseServer() else {
        throw ServerLocatorError.noUrl
      }
      return url
    }

    rootTask = task

    return try await task.value
  }

  private func ping(server: URL) async throws -> PingResult {
      let date = Date()

      let request = try await self.requestor.request(
        url: server,
        Root<Version>.self,
        timeoutInterval: 2,
        invalidateAfterError: false,
        useCache: false
      )

      return PingResult(
        server: request,
        timeInterval: abs(date.timeIntervalSinceNow)
      )
  }

  private func selectHost(
    localUrl: Connection, remoteUrl: Connection
  ) async throws -> Connection? {
    async let local = ping(server: localUrl.uri)
    async let remote = ping(server: remoteUrl.uri)

    do {
      _ = try await local
      storage.lastUsedConnection = localUrl
      return localUrl
    } catch {
      logger.error("local not succeeded \(error)")
    }

    do {
      _ = try await remote
      storage.lastUsedConnection = remoteUrl
      return remoteUrl
    } catch {
      logger.error("remote not succeeded \(error)")
      throw error
    }
  }

  nonisolated func devices() async throws -> [DeviceResponse] {
    let devices = try await requestor.request(
      url: URL(string: "https://plex.tv/api/v2/resources")!,
      [DeviceResponse].self,
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
      self.devices = devices
    }

    return devices
  }

  private func executePings(
    servers: [Connection]
  ) async throws -> Connection? {

    return await withTaskGroup(of: Connection?.self) { group in
      for server in servers {
        _ = group.addTaskUnlessCancelled {
          do {
            _ = try await self.ping(server: server.uri)
            try Task.checkCancellation()
            return server
          } catch {
            self.logger.error("Pings error: \(server.address) \(error)")
            return nil
          }
        }
      }

      for await result in group {
        if let result {
          group.cancelAll()
          return result
        }
      }
      return nil
    }
  }

  private func chooseServer() async throws -> Connection? {
    let servers = try await devices()
      .flatMap { server in
        server.connections.filter { $0.protocol == "https" }
      }
    //      .flatMap { server in
    //        URL(string: server.uri).map { [(server, $0)] } ?? []
    //      }

    let serversGroupedByLocal = Dictionary(grouping: servers, by: {
      $0.local
    })

    async let localPings = executePings(
      servers: serversGroupedByLocal[true] ?? []
    )
    async let remotePings = executePings(
      servers: serversGroupedByLocal[false] ?? []
    )

    let choice: Connection?

    if let local = try? await localPings {
      choice = local
    } else if let remote = try await remotePings {
      choice = remote
    } else {
      choice = nil
    }

    self.connection = choice
    storage.lastUsedConnection = choice

    let local = try? await localPings
    let remote = try? await remotePings

    storage.lastUsedLocalConnection = local
    storage.lastUsedRemoteConnection = remote

    return choice
  }

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
