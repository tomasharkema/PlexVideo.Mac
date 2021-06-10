//
//  ServerLocator.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 09/06/2021.
//

import Foundation

enum ServerLocatorError: LocalizedError {
  case noUrl
}

actor ServerLocatorData {
  var lastUsedRoot: URL?
  var retrieveLastUsedHostTask: Task.Handle<URL?, Never>?

  func set(lastUsedRoot: URL?) {
    self.lastUsedRoot = lastUsedRoot
  }

  func set(retrieveLastUsedHostTask: Task.Handle<URL?, Never>?) {
    self.retrieveLastUsedHostTask = retrieveLastUsedHostTask
  }

//  public func run<T>(resultType: T.Type = T.self, body: (ServerLocatorData) throws -> T) async rethrows -> T {
//    return try body(self)
//  }
}

class ServerLocator: ObservableObject {
  static let locator = ServerLocator()
  private let requestor = Requestor.shared

  private(set) var hasForceTried: Bool = false

  private var data = ServerLocatorData()

  @MainActor @Published private(set) var connection: Connection?

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
        throw ServerLocatorError.noUrl
      }

      await data.set(lastUsedRoot: url)
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
      await data.set(lastUsedRoot: l)
      return l
    } else if case .success = await remote {
      await data.set(lastUsedRoot: r)
      return r
    } else {
      return nil
    }
  }

  private func retrieveLastUsedHost(force: Bool = false) async -> URL? {
    if let lastUsedRoot = await data.lastUsedRoot, !force {
      return lastUsedRoot
    }

    if let hangingTask = await data.retrieveLastUsedHostTask {
      return try? await hangingTask.get()
    }

    let task = asyncDetached { () -> URL? in
      defer { async { await data.set(retrieveLastUsedHostTask: nil) } }
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

//    await data.run {
//      $0.retrieveLastUsedHostTask = task
//    }

    await data.set(retrieveLastUsedHostTask: task)
    return await task.get()
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

    await MainActor.run {
      self.connection = choice?.0
    }

    return choice?.1
  }

  private var invalidateTask: Task.Handle<Void, Never>?
  func invalidate() async {
    if let invalidateTask = invalidateTask {
      await invalidateTask.get()
      return
    }
    invalidateTask = async {
      await data.set(lastUsedRoot: nil)
//      lastUsedRoot = nil

      do {
        try await root(force: true)
      } catch {
        print(error)
      }
      invalidateTask = nil
    }
  }
}
