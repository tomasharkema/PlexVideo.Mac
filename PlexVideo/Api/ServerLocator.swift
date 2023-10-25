//
//  ServerLocator.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 09/06/2021.
//

import AsyncAwaitHelpers
import Foundation

enum ServerLocatorError: LocalizedError {
  case noUrl
}

class ServerLocator: ObservableObject {
  static let locator = ServerLocator()
  private let requestor = Requestor.shared

  private(set) var lastTriedRootDate: Date?
  private(set) var lastForceTryDate: Date?
  private(set) var lastConfirmedUrl: URL?
  private let pingOnce = Once<URL, (Root<Version>, TimeInterval), Error>()

  @MainActor @Published private(set) var connection: Connection?

  private let rootOnce = OnceSingle<URL, Error>()
  private let rootForceOnce = OnceSingle<URL, Error>()
  private let invalidateOnce = OnceSingle<Void, Never>()

  func root(force: Bool = false) async throws -> URL {
    if force {
      return try await rootForceOnce.onceKeepOriginal(
        Task {
          guard let url = try await chooseServer() else {
            throw ServerLocatorError.noUrl
          }
          lastForceTryDate = Date()
          return url
        }
      ).value
    }

    if let lastConfirmedUrl {
      return lastConfirmedUrl
    }

    return try await rootOnce.onceKeepOriginal(
      Task {
        // phase 1: check for last used root and if its still viable...
        do {
          if let lastUsed = await Storage.shared.lastUsedRoot {
            if lastTriedRootDate == nil {
              _ = try await ping(server: lastUsed)
              lastTriedRootDate = Date()
            }
            lastConfirmedUrl = lastUsed
            return lastUsed
          }
        } catch {
          await MainActor.run {
            Storage.shared.lastUsedRoot = nil
          }
          print("lastUsedRoot not viable... continuing! \(error)")
        }

        // phase 2: check if saved local and remote ip's are still viable
        do {
          if let localHost = await Storage.shared.lastUsedLocalHost,
             let remoteHost = await Storage.shared.lastUsedRemoteHost,
             let url = try await selectHost(l: localHost, r: remoteHost)
          {
            return url
          }
        } catch {
          await MainActor.run {
            Storage.shared.lastUsedLocalHost = nil
            Storage.shared.lastUsedRemoteHost = nil
          }
          print("lastUsedLocalHost and lastUsedRemoteHost not viable... continuing! \(error)")
        }

        // phase 3: refetch potential servers to connect to
        guard let url = try await chooseServer() else {
          throw ServerLocatorError.noUrl
        }
        return url
      }
    ).value
  }

  private func ping(server: URL) async throws -> (Root<Version>, TimeInterval) {
    try await pingOnce.onceKeepOriginal(key: server, keepInCache: 60) {
      let date = Date()
      return try await (
        self.requestor.request(url: server, timeoutInterval: 2, invalidateAfterError: false),
        abs(date.timeIntervalSinceNow)
      )
    }.value
  }

  private func selectHost(l: URL, r: URL) async throws -> URL? {
    async let local = ping(server: l)
    async let remote = ping(server: r)

    do {
      _ = try await local
      await MainActor.run {
        Storage.shared.lastUsedRoot = l
      }
      return l
    } catch {
      print("local not succeeded \(error)")
    }

    do {
      _ = try await remote
      await MainActor.run {
        Storage.shared.lastUsedRoot = r
      }
      return r
    } catch {
      print("remote not succeeded \(error)")
      throw error
    }
  }

  func devices() async throws -> [Device] {
    try await requestor.request(
      url: URL(string: "https://plex.tv/api/v2/resources")!,
      queryItems: [
        URLQueryItem(name: "includeHttps", value: "1"),
        URLQueryItem(name: "includeRelay", value: "1"),
      ]
    )
  }

  private func executePings(servers: [(Connection, URL)]) async throws
    -> (Connection, URL)?
  {
    try await whenAny(
      servers.map { server in
        { () -> (Connection, URL)? in
          do {
            _ = try await self.ping(server: server.1)
            return (server.0, server.1)
          } catch {
            print(error)
            return nil
          }
        }
      }
    )
  }

  private func chooseServer() async throws -> URL? {
    let servers = try await devices()
      .filter {
        $0.provides.contains("server")
      }
      .flatMap { server in
        server.connections.filter { $0.protocol == "https" }
      }
      .flatMap { server in
        URL(string: server.uri).map { [(server, $0)] } ?? []
      }

    let serversGroupedByLocal = Dictionary(
      grouping: servers,
      by: {
        $0.0.local
      }
    )

    async let localPings = executePings(servers: serversGroupedByLocal[true] ?? [])
    async let remotePings = executePings(servers: serversGroupedByLocal[false] ?? [])

    let choice: (Connection, URL)? =
      if let local = try? await localPings
    {
      local
    } else if let remote = try await remotePings {
      remote
    } else {
      nil
    }

    await MainActor.run {
      Storage.shared.lastUsedRoot = choice?.1

      self.connection = choice?.0
    }

    let local = try? await localPings
    let remote = try? await remotePings

    await MainActor.run {
      Storage.shared.lastUsedLocalHost = local?.1
      Storage.shared.lastUsedRemoteHost = remote?.1
    }

    return choice?.1
  }

  func invalidate() async {
    _ = await invalidateOnce.onceKeepOriginal(
      Task {
        lastConfirmedUrl = nil
        await MainActor.run {
          Storage.shared.lastUsedRoot = nil
        }
        do {
          _ = try await root(force: true)
        } catch {
          print(error)
        }
      }
    ).value
  }
}
