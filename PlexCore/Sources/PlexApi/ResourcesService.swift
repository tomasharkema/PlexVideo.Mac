//
//  ResourcesService.swift
//
//
//  Created by Tomas Harkema on 23/10/2023.
//

import AsyncHelpers
import Dependencies
import Foundation
import OSLog
import PlexShared
//import SwiftMacros
import SwiftStacktrace

public struct ResourcesService: Sendable {
  private let logger = Logger(subsystem: "PlexVideo", category: "ResourcesService")

  @Dependency(\.requestor)
  private var requestor

  @Dependency(\.serverLocatorStorageProviding)
  private var storage

  @Dependency(\.plexWebEndpoint)
  private var plexWebEndpoint

  package init() {}

  @Dependency(\.networkManager)
  private var networkManager

  func ping(
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
        let error = PingResultErrorDetails.noMetric
        return .failure(
          serverWithConnection: server,
          error: error,
          stacktraceError: StacktraceError(error)
        )
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
      return .failure(
        serverWithConnection: server,
        error: .urlError(error),
        stacktraceError: StacktraceError(error)
      )
    } catch {
      //      logger.error("ping error: \(error)")
      logger.error("ping error: \(server.server.name) \(server.connection.address)")
      return .failure(
        serverWithConnection: server,
        error: .otherError(error),
        stacktraceError: StacktraceError(error)
      )
    }
  }

  nonisolated func devices() async throws -> [Server] {
    let plexWebEndpoint = self.plexWebEndpoint
    return try await EnsureOnce.once(cacheDuration: .seconds(60 * 5)) {
      try await plexWebEndpoint.provider().resources()
    }
  }

  package nonisolated func capabilities(server: Server) async throws -> Root<Capabilities> {
    var multipleError: MultipleError? = nil
    for connection in server.connections {
      do {
        let pingResult = try await ping(
          server: .init(server: server, connection: connection),
          timeout: .seconds(1)
        ).details.get().result
        guard let pingResult else {
          continue
        }
        return pingResult
      } catch {
        logger.error("capabilities error: \(error)")
        if multipleError != nil {
          multipleError!.append(StacktraceError(error))
        } else {
          multipleError = MultipleError(StacktraceError(error))
        }
      }
    }
    throw multipleError ?? StacktraceError(NSError(domain: "DERP", code: 69))
  }

  nonisolated func servers() async throws -> ServersResponse {
    try await EnsureOnce.once(cacheDuration: .seconds(60 * 5)) {
      let servers = try await self.devices()
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
              let capabilities = try await self.capabilities(server: server)

              //              let caps: Result<Root<Capabilities>, any Error> =
              //              if let result = capabilities {
              //                .success(result)
              //              } else {
              //                .failure(NSError(domain: "null error", code: 69))
              //              }
              return ServerAndCapabilities(
                server: server,
                capabilities: .success(capabilities)
              )
            } catch {
              return ServerAndCapabilities(
                server: server,
                capabilities: .failure(error)
              )
              //              throw error
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
      return response
    }
  }
}

extension DependencyValues {
  public var resourcesService: ResourcesService {
    get { self[ResourcesServiceKey.self] }
    set { self[ResourcesServiceKey.self] = newValue }
  }
}

private struct ResourcesServiceKey: DependencyKey {
  static let liveValue: ResourcesService = .init()
}
