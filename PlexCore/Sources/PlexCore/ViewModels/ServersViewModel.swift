//
//  ServersViewModel.swift
//
//
//  Created by Tomas Harkema on 23/10/2023.
//

import Foundation
import Inject
import Observation
import PlexApi
import PlexShared
import Processed

public struct KeyValue: Hashable, Identifiable {
  public let key: String
  public let value: String

  public let id = UUID()
}

@MainActor
@Observable
public final class ServersViewModel {

  private var pinger = ServerPinger()

  //  @InjectedObserving(\.serverLocator)
  private var serverLocator: ServerLocator = InjectedValues.get(\.serverLocator)

  public private(set) var keyValueInfo = [Server.ID: [KeyValue]]()

  public private(set) var rawResults = [Server.ID: (String, String)]()

  public init() {
    observe()
  }

  private func observe() {
    withObservationTracking(
      {
        _ = serverLocator.servers
      },
      onChange: {
        Task { @MainActor in
          self.updateInfo()
        }
      }
    )
    withObservationTracking(
      {
        _ = serverLocator.servers
      },
      onChange: {
        Task { @MainActor in
          self.updateRawInfo()
        }
      }
    )
  }

  private func updateInfo() {
    guard let servers = serverLocator.servers else {
      return
    }
    var keyValues = [Server.ID: [KeyValue]]()
    for server in servers {
      keyValues[server.server.server.id] = [
        KeyValue(key: "ID", value: server.id.rawValue),
        KeyValue(key: "Public IP", value: server.server.server.publicAddress),
      ]
    }
    self.keyValueInfo = keyValues
  }

  private func updateRawInfo() {
    guard let servers = serverLocator.servers else {
      return
    }
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
    self.rawResults = rawInfos
  }

  public var servers: ServersResponse? {
    serverLocator.servers
  }

  public var currentConnection: ServerWithCurrentConnection? {
    serverLocator.connection
  }

  public var pings: LoadableState<PingerState> {
    pinger.state
  }

  public func start() {
    pinger.startPinging()
  }

  public func stop() {
    pinger.stopPinging()
  }
}
