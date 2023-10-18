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

enum ServerLocatorError: LocalizedError {
  case noUrl
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

  public nonisolated init() { }

  public func rootForced(deviceInfo: DeviceInfo) async throws -> Connection {

    if let rootForcedTask {
      return try await rootForcedTask.value
    }

    defer {
      rootForcedTask = nil
    }

    let task = Task {
      guard let connection = try await chooseServer(deviceInfo: deviceInfo) else {
        throw ServerLocatorError.noUrl
      }
      lastForceTryDate = Date()
      return connection
    }

    rootForcedTask = task

    return try await task.value
  }

  public func root(force: Bool = false, deviceInfo: DeviceInfo) async throws -> Connection {
    if force {
      rootTask?.cancel()
      rootTask = nil
      return try await rootForced(deviceInfo: deviceInfo)
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
            _ = try await ping(server: lastUsedConnection.uri, deviceInfo: deviceInfo)
            lastTriedRootDate = Date()
          }
          self.connection = lastUsedConnection
          return lastUsedConnection
        }
      } catch {
        storage.lastUsedConnection = nil
        logger.error("lastUsedRoot not viable... continuing! \(error)")
      }

      // phase 2: check if saved local and remote ip's are still viable
      do {
        if let localConnection = self.storage.lastUsedLocalConnection,
           let remoteConnection = self.storage.lastUsedRemoteConnection,
           let connection = try await selectHost(localUrl: localConnection, remoteUrl: remoteConnection, deviceInfo: deviceInfo) {
          self.connection = connection
          return connection
        }
      } catch {
        storage.lastUsedLocalConnection = nil
        storage.lastUsedRemoteConnection = nil

        logger.error("lastUsedLocalHost and lastUsedRemoteHost not viable... continuing! \(error)")
      }

      // phase 3: refetch potential servers to connect to
      guard let url = try await chooseServer(deviceInfo: deviceInfo) else {
        throw ServerLocatorError.noUrl
      }
      return url
    }

    rootTask = task

    return try await task.value
  }

  private func ping(server: URL, deviceInfo: DeviceInfo) async throws -> (Root<Version>, TimeInterval) {
//    if let pingingTask {
//      return try await pingingTask.value
//    }
//    
//    defer {
//      pingingTask = nil
//    }

//    let task = Task {
      let date = Date()

      let request: Root<Version> = try await self.requestor.request(
        url: server,
        deviceInfo: deviceInfo,
        timeoutInterval: 2,
        invalidateAfterError: false,
        useCache: false
      )

      return (
        request,
        abs(date.timeIntervalSinceNow)
      )
//    }

//    pingingTask = task

//    return try await task.value
  }

  private func selectHost(
    localUrl: Connection, remoteUrl: Connection, deviceInfo: DeviceInfo
  ) async throws -> Connection? {
    async let local = ping(server: localUrl.uri, deviceInfo: deviceInfo)
    async let remote = ping(server: remoteUrl.uri, deviceInfo: deviceInfo)

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

  func devices(deviceInfo: DeviceInfo) async throws -> [DeviceResponse] {
    try await requestor.request(
      url: URL(string: "https://plex.tv/api/v2/resources")!,
      deviceInfo: deviceInfo,
      queryItems: [
        URLQueryItem(name: "includeHttps", value: "1"),
        URLQueryItem(name: "includeRelay", value: "1")
      ],
      useCache: false
    )
  }

  private func executePings(
    servers: [Connection],
    deviceInfo: DeviceInfo
  ) async throws -> Connection? {

    return await withTaskGroup(of: Connection?.self) { group in
      for server in servers {
        _ = group.addTaskUnlessCancelled {
          do {
            _ = try await self.ping(server: server.uri, deviceInfo: deviceInfo)
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

  private func chooseServer(deviceInfo: DeviceInfo) async throws -> Connection? {
    let servers = try await devices(deviceInfo: deviceInfo)
      .filter {
        $0.provides.contains("server")
      }
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
      servers: serversGroupedByLocal[true] ?? [],
                                        deviceInfo: deviceInfo
    )
    async let remotePings = executePings(
      servers: serversGroupedByLocal[false] ?? [],
                                         deviceInfo: deviceInfo
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

  func invalidate(deviceInfo: DeviceInfo) async {

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
      _ = try await root(force: true, deviceInfo: deviceInfo)
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
