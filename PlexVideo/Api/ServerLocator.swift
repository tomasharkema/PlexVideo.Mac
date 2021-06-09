//
//  ServerLocator.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 09/06/2021.
//

import Foundation

class ServerLocator: ObservableObject {
  static let locator = ServerLocator()
  private let requestor = Requestor()

  private var lastUsedRoot: URL?
  private var retrieveLastUsedHostTask: Task.Handle<URL?, Never>?

  private(set) var hasForceTried: Bool = false
  @Published private(set) var connection: Connection?

  func root(force: Bool = false) async throws -> URL {
    do {
      if let lastUsed = await retrieveLastUsedHost(force: force), !force {
        if !hasForceTried {
          hasForceTried = true
          asyncDetached(priority: .background, operation: {
            try await root(force: true)
          })
        }

        return lastUsed
      }

      guard let url = try await chooseServer() else {
        throw NSError(domain: "NO URL", code: 0, userInfo: nil)
      }

      lastUsedRoot = url

      return url
    } catch {
      print("ERROR!", error)
      throw error
    }
  }

  private func ping(server: URL) async -> Result<(Root<Version>, TimeInterval), Error> {
    do {
      let date = Date()
      return .success((
        try await requestor.request(url: server, timeoutInterval: 2),
        Date().timeIntervalSince(date)
      ))
    } catch {
      return .failure(error)
    }
  }

  private func selectHost(l: URL, r: URL) async -> URL? {
    async let local = ping(server: l)
    async let remote = ping(server: r)

    if case .success = await local {
      lastUsedRoot = l
      return l
    } else if case .success = await remote {
      lastUsedRoot = r
      return r
    } else {
      return nil
    }
  }

  private func retrieveLastUsedHost(force: Bool = false) async -> URL? {
    if let lastUsedRoot = lastUsedRoot, !force {
      return lastUsedRoot
    }

    if let hangingTask = retrieveLastUsedHostTask {
      return try? await hangingTask.getResult().get()
    }

    let task = asyncDetached { () -> URL? in
      defer { retrieveLastUsedHostTask = nil }
      if let lastUsedLocalHost = await Storage.shared.lastUsedLocalHost,
         let lastUsedRemoteHost = await Storage.shared.lastUsedRemoteHost,
         let localHost = URL(string: lastUsedLocalHost),
         let remoteHost = URL(string: lastUsedRemoteHost),
         !force
      {
        return await selectHost(l: localHost, r: remoteHost)
      }
      return nil
    }

    retrieveLastUsedHostTask = task

    return try? await task.getResult().get()
  }

  func devices() async throws -> [Device] {
    return try await requestor.request(
      url: URL(string: "https://plex.tv/api/v2/resources")!,
      queryItems: [
        URLQueryItem(name: "includeHttps", value: "1"),
        URLQueryItem(name: "includeRelay", value: "1"),
      ]
    )
  }

  private func chooseServer() async throws -> URL? {
    let d = try await devices()
    print(d)

    let servers = d
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

    // TODO: fix async let

    async let localPings = withTaskGroup(of: [(Connection, URL, TimeInterval)]
      .self) { group -> [(Connection, URL, TimeInterval)] in
      for server in serversGroupedByLocal[true] ?? [] {
        group.async {
          if case let .success(r) = await self.ping(server: server.1) {
            return [(server.0, server.1, r.1)]
          } else {
            return []
          }
        }
      }
      return await group.reduce([], +)
    }

    async let remotePings = withTaskGroup(of: [(Connection, URL, TimeInterval)]
      .self) { group -> [(Connection, URL, TimeInterval)] in
      for server in serversGroupedByLocal[false] ?? [] {
        group.async {
          if case let .success(r) = await self.ping(server: server.1) {
            return [(server.0, server.1, r.1)]
          } else {
            return []
          }
        }
      }
      return await group.reduce([], +)
    }

    let local = await localPings.sorted {
      $0.2 < $1.2
    }.first

    let remote = await remotePings.sorted {
      $0.2 < $1.2
    }.first

    DispatchQueue.main.async {
      Storage.shared.lastUsedLocalHost = local?.1.absoluteString
      Storage.shared.lastUsedRemoteHost = remote?.1.absoluteString
    }

    let choice = local ?? remote

    DispatchQueue.main.async {
      self.connection = choice?.0
    }

    return choice?.1
  }
}
