//
//  NetworkManager.swift
//
//
//  Created by Tomas Harkema on 20/10/2023.
//

import Asynchrone
import Foundation
import Inject
import OSLog

public final class NetworkManager: NSObject, Sendable {
  fileprivate let logger = Logger(subsystem: "PlexVideo", category: "NetworkManager")

  private let delegate: NetworkManagerDelegate
  public let session: URLSession

  private let metricsStream:
    SharedAsyncSequence<
      AsyncStream<
        (
          URLSessionTaskTransactionMetrics,
          UUID
        )
      >
    >

  override init() {
    let delegate = NetworkManagerDelegate()
    let stream = AsyncStream<(URLSessionTaskTransactionMetrics, UUID)> { continuation in
      delegate.continuation = continuation
    }.shared()
    self.delegate = delegate
    metricsStream = stream
    session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
  }

  public func getMetrics(
    for uuid: UUID,
    withTimeout timeout: Duration
  ) async -> URLSessionTaskTransactionMetrics? {
    await withTaskGroup(
      of: URLSessionTaskTransactionMetrics?.self
    ) { group in
      group.addTask {
        do {
          let result = try await self.metricsStream.first { $0.1 == uuid }?.0
          if let result {
            return result
          } else {
            return nil
          }
        } catch {
          self.logger.error("got metric error: \(error)")
          return nil
        }
      }
      group.addTask {
        try? await Task.sleep(for: timeout)
        return nil
      }

      for await res in group {
        if let res {
          group.cancelAll()
          return res
        }
      }
      return nil
    }
  }
}

class NetworkManagerDelegate: NSObject, URLSessionDataDelegate {
  fileprivate var continuation: AsyncStream<(URLSessionTaskTransactionMetrics, UUID)>.Continuation!

  public nonisolated func urlSession(
    _: URLSession,
    task _: URLSessionTask,
    didFinishCollecting metrics: URLSessionTaskMetrics
  ) {
    for metric in metrics.transactionMetrics {
      let uuid = metric.request.value(forHTTPHeaderField: "X-MetricsUUID")
        .flatMap { UUID(uuidString: $0) }
      guard let uuid else {
        return
      }
      Task {
        continuation.yield((metric, uuid))
      }
    }
  }
}

extension InjectedValues {
  public var networkManager: NetworkManager {
    get { Self[NetworkManagerKey.self] }
    set { Self[NetworkManagerKey.self] = newValue }
  }
}

public struct NetworkManagerKey: InjectionKey {
  public static var currentValue: NetworkManager? = .init()
}
