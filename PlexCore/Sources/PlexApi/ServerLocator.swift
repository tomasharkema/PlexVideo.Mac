//
//  ServerLocator.swift
//
//
//  Created by Tomas Harkema on 09/06/2021.
//

import Foundation
import AsyncAwaitHelpers
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

  @Injected(\.storage)
  private var storage
  
  private(set) var lastTriedRootDate: Date?
  private(set) var lastForceTryDate: Date?
  private(set) var lastConfirmedUrl: URL?
  private let pingOnce = Once<URL, (Root<Version>, TimeInterval), any Error>()

  @Published
  public private(set) var connection: Connection?

  private let rootOnce = OnceSingle<URL, any Error>()
  private let rootForceOnce = OnceSingle<URL, any Error>()
  private let invalidateOnce = OnceSingle<Void, Never>()

  public nonisolated init() { }

  public func root(force: Bool = false, deviceInfo: DeviceInfo) async throws -> URL {
    if force {
      return try await rootForceOnce.onceKeepOriginal(Task {
        guard let url = try await chooseServer(deviceInfo: deviceInfo) else {
          throw ServerLocatorError.noUrl
        }
        lastForceTryDate = Date()
        return url
      }).value
    }

    if let lastConfirmedUrl = lastConfirmedUrl {
      return lastConfirmedUrl
    }

    return try await rootOnce.onceKeepOriginal(Task {
      // phase 1: check for last used root and if its still viable...
      do {
        if let lastUsed = await storage.lastUsedRoot {
          if lastTriedRootDate == nil {
            _ = try await ping(server: lastUsed,
                               deviceInfo: deviceInfo)
            lastTriedRootDate = Date()
          }
          lastConfirmedUrl = lastUsed
          return lastUsed
        }
      } catch {
        await MainActor.run {
          storage.lastUsedRoot = nil
        }
        logger.error("lastUsedRoot not viable... continuing! \(error)")
      }

      // phase 2: check if saved local and remote ip's are still viable
      do {
        if let localHost = storage.lastUsedLocalHost,
           let remoteHost = storage.lastUsedRemoteHost,
           let url = try await selectHost(localUrl: localHost, remoteUrl: remoteHost, deviceInfo: deviceInfo)
        {
          return url
        }
      } catch {
        await MainActor.run {
          storage.lastUsedLocalHost = nil
          storage.lastUsedRemoteHost = nil
        }

        logger.error("lastUsedLocalHost and lastUsedRemoteHost not viable... continuing! \(error)")
      }

      // phase 3: refetch potential servers to connect to
      guard let url = try await chooseServer(deviceInfo: deviceInfo) else {
        throw ServerLocatorError.noUrl
      }
      return url
    }).value
  }

  private func ping(server: URL, deviceInfo: DeviceInfo) async throws -> (Root<Version>, TimeInterval) {
    return try await pingOnce.onceKeepOriginal(key: server, keepInCache: 60) {
      let date = Date()
      return (
        try await self.requestor.request(url: server, deviceInfo: deviceInfo, timeoutInterval: 2, invalidateAfterError: false),
        abs(date.timeIntervalSinceNow)
      )
    }.value
  }

  private func selectHost(localUrl: URL, remoteUrl: URL, deviceInfo: DeviceInfo) async throws -> URL? {
    async let local = ping(server: localUrl, deviceInfo: deviceInfo)
    async let remote = ping(server: remoteUrl, deviceInfo: deviceInfo)

    do {
      _ = try await local
      await MainActor.run {
        storage.lastUsedRoot = localUrl
      }
      return localUrl
    } catch {
      logger.error("local not succeeded \(error)")
    }

    do {
      _ = try await remote
      await MainActor.run {
        storage.lastUsedRoot = remoteUrl
      }
      return remoteUrl
    } catch {
      logger.error("remote not succeeded \(error)")
      throw error
    }
  }

  func devices(deviceInfo: DeviceInfo) async throws -> [Device] {
    try await requestor.request(
      url: URL(string: "https://plex.tv/api/v2/resources")!,
      deviceInfo: deviceInfo,
      queryItems: [
        URLQueryItem(name: "includeHttps", value: "1"),
        URLQueryItem(name: "includeRelay", value: "1"),
      ]
    )
  }

  private func executePings(servers: [(Connection, URL)], deviceInfo: DeviceInfo) async throws
    -> (Connection, URL)?
  {
    try await whenAny(servers.map { server in
      return { () -> (Connection, URL)? in
        do {
          _ = try await self.ping(server: server.1, deviceInfo: deviceInfo)
          return (server.0, server.1)
        } catch {
          self.logger.error("Pings error: \(server.0.address) \(error)")
          return nil
        }
      }
    })
  }

  private func chooseServer(deviceInfo: DeviceInfo) async throws -> URL? {
    let servers = try await devices(deviceInfo: deviceInfo)
      .filter {
        $0.provides.contains("server")
      }
      .flatMap { server in
        server.connections.filter { $0.protocol == "https" }
      }
      .flatMap { server in
        URL(string: server.uri).map { [(server, $0)] } ?? []
      }

    let serversGroupedByLocal = Dictionary(grouping: servers, by: {
      $0.0.local
    })

    async let localPings = executePings(servers: serversGroupedByLocal[true] ?? [],
                                        deviceInfo: deviceInfo)
    async let remotePings = executePings(servers: serversGroupedByLocal[false] ?? [],
                                         deviceInfo: deviceInfo)

    let choice: (Connection, URL)?

    if let local = try? await localPings {
      choice = local
    } else if let remote = try await remotePings {
      choice = remote
    } else {
      choice = nil
    }

    await MainActor.run {
      storage.lastUsedRoot = choice?.1

      self.connection = choice?.0
    }

    let local = try? await localPings
    let remote = try? await remotePings

    await MainActor.run {
      storage.lastUsedLocalHost = local?.1
      storage.lastUsedRemoteHost = remote?.1
    }

    return choice?.1
  }

  func invalidate(deviceInfo: DeviceInfo) async {
    _ = await invalidateOnce.onceKeepOriginal(Task {
      lastConfirmedUrl = nil
      await MainActor.run {
        storage.lastUsedRoot = nil
      }
      do {
        _ = try await root(force: true, deviceInfo: deviceInfo)
      } catch {
        logger.error("invalidate error: \(error)")
      }
    }).value
  }
}

public extension InjectedValues {
  var serverLocator: ServerLocator {
    get { Self[ServerLocatorKey.self] }
    set { Self[ServerLocatorKey.self] = newValue }
  }
}

private struct ServerLocatorKey: InjectionKey {
  static var currentValue: ServerLocator = .init()
}
