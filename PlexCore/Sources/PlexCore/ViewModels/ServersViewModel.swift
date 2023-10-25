//
//  ServersViewModel.swift
//
//
//  Created by Tomas Harkema on 23/10/2023.
//

import Foundation
import Inject
import Observation
import OSLog
import PlexApi
import PlexShared
import Processed

public struct KeyValue: Hashable, Identifiable {
  public let key: String
  public let value: String

  public var id: String {
    key
  }
}

@MainActor
@Observable
public final class ServersViewModel: LoadableSupport {
  private let logger = Logger(subsystem: "PlexVideo", category: "ServersViewModel")

  @ObservationIgnored
  @Injected(\.api)
  private var api

//  @ObservationIgnored
//  @Injected(\.videosDataSource)
  private var videosDataSource = InjectedValues.get(\.videosDataSource)

//  @ObservationIgnored
//  @Injected(\.serverPinger)
  private var pinger = InjectedValues.get(\.serverPinger)

  private var serverLocator: ServerLocator = InjectedValues.get(\.serverLocator)

  public private(set) var keyValueInfo = [Server.ID: [KeyValue]]()

  public private(set) var rawResults = [Server.ID: (String, String)]()

  public private(set) var sessions: LoadableState<[Server.ID: [SessionVideo]]> = .absent

  public private(set) var servers = [ServerAndPings]()

  public init() {
    observe()
  }

  public var pingerDate: Date? {
    pinger.state.data?.lastRun
  }

  private func observe() {
    withObservationTracking({
      _ = (serverLocator.servers, pinger.state)
    }, onChange: {
      Task { @MainActor in
        try? await self.updateInfo()
      }
      Task { @MainActor in
        try? await self.updateRawInfo()
      }
      Task {
        await self.updateServerResult()
      }
      Task { @MainActor in
        self.observe()
      }
    })
  }

  private func pings(
    data: PingerState?,
    server: ServerAndCapabilities
  ) -> ServerAndPings {
    let pings: [PingResult] = server.connections
      .map {
        data?.results[$0.id] ?? PingResult(
          serverWithConnection: $0,
          details: .failure(PingResultError(
            serverWithConnection: $0,
            details: .noMetric
          ))
        )
      }
      .sorted { lhs, rhs in
        guard let lResult = try? lhs.get() else {
          return false
        }
        guard let rResult = try? rhs.get() else {
          return true
        }

        if lResult.serverWithConnection.connection.local {
          return true
        }
        return false
      }

    return ServerAndPings(server: server.server, pings: pings)
  }

  private func updateServerResult() async {
    guard let servers = serverLocator.servers else {
      return
    }
    let data = pinger.state.data
    let results: [ServerAndPings] = servers.map {
      self.pings(data: data, server: $0)
    }

    await MainActor.run {
      self.servers = results
    }
  }

  private func updateInfo() async throws {
    let servers = try await serverLocator.getServers()

    var keyValues = [Server.ID: [KeyValue]]()
    for server in servers {
      keyValues[server.server.id] = [
        KeyValue(key: "ID", value: server.id.rawValue),
        KeyValue(key: "Public IP", value: server.server.publicAddress),
      ]
    }
    keyValueInfo = keyValues
  }

  private func updateRawInfo() async throws {
    let servers = try await serverLocator.getServers()

    var rawInfos = [Server.ID: (String, String)]()
    for server in servers {
      let enc = JSONEncoder()
      enc.outputFormatting = [.prettyPrinted, .sortedKeys]

      let serverString =
        (try? enc.encode(server.server)).flatMap {
          String(data: $0, encoding: .utf8)
        } ?? "{}"

      let capabilitiesString =
        (try? enc.encode(server.capabilities.get())).flatMap {
          String(data: $0, encoding: .utf8)
        } ?? "{}"

      rawInfos[server.id] = (serverString, capabilitiesString)
    }
    rawResults = rawInfos
  }

  private func startSessions() {
    load(\.sessions) { yield in
      while !Task.isCancelled {
        let sessions = await self.getSessions()
        try Task.checkCancellation()
        yield(.loaded(sessions))
        try await Task.sleep(seconds: 10)
      }
    }
  }

  private func stopSessions() {
    cancel(\.sessions)
  }

  private func getSessions() async -> [Server.ID: [SessionVideo]] {
    do {
      let servers = try await serverLocator.getServers()
      let videos = await videosDataSource.getData()

      return await withTaskGroup(
        of: (Server.ID, [SessionVideo])?.self,
        returning: [Server.ID: [SessionVideo]].self
      ) { group in
        for server in servers {
          group.addTask {
            do {
              let server = try await self.serverLocator.root(server: server.server)
              let sessions: [SessionVideo] = try await self.api.sessions(server: server)
                .mediaContainer.metadata
                .compactMap { session in
                  guard let video = videos?.videosById[session.videoID] else {
                    return nil
                  }

                  return SessionVideo(video: video, session: session)
                }
              return (server.server.id, sessions)
            } catch {
              self.logger.error("session error: \(error)")
              return nil
            }
          }
        }
        return await group.reduce(into: [:]) { prev, curr in
          if let curr {
            prev[curr.0] = curr.1
          }
        }
      }
    } catch {
      logger.error("session error: \(error)")
      return [:]
    }
  }

  public var currentConnection: [Server.ID: ServerWithCurrentConnection] {
    serverLocator.connection
  }

//  public var pings: LoadableState<PingerState> {
//    pinger.state
//  }

  public func start() {
    startSessions()
  }

  public func stop() {
    stopSessions()
  }
}
