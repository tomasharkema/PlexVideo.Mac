//
//  VideosDataSource.swift
//
//
//  Created by Tomas Harkema on 24/10/2023.
//

import Dependencies
import Foundation
import OSLog
import PlexApi
import PlexShared
import Processed

@MainActor
@Observable
public final class VideosDataSource: LoadableSupport {
  private let logger = Logger(subsystem: "PlexVideo", category: "VideosDataSource")

  @ObservationIgnored
  @Dependency(\.videoDataService)
  private var service

  @ObservationIgnored
  @Dependency(\.storage)
  private var storage

  @ObservationIgnored
  @Dependency(\.api)
  private var api

  @ObservationIgnored
  @Dependency(\.serverLocator)
  private var serverLocator

  private var loadingTask: Task<Void, Never>?

  public private(set) var data: LoadableState<Data> = .absent

  public private(set) var savedLastPlayed: Video?

  nonisolated init() {
    Task { @MainActor in
      track()
    }
  }

  @MainActor
  private func track() {
    withObservationTracking({
      _ = serverLocator.servers
    }, onChange: {
      Task { @MainActor in
        self.serversChanged()
        self.track()
      }
    })
  }

  private func serversChanged() {
    Task {
      if data.isLoading || data.isError {
        self.reset(\.data)
        await self.load(silently: false, reload: true)
      }
    }
  }

  func getData() async -> Data? {
    if let data = data.data {
      return data
    }
    if let loadingTask {
      await loadingTask.value
    }
    if let data = data.data {
      return data
    }
    return nil
  }

  public func reload(silently: Bool, minimalTime: Duration = .seconds(1)) async {
    await withDiscardingTaskGroup { group in
      group.addTask {
        await self.load(silently: silently, reload: true)
      }
      group.addTask {
        try? await Task.sleep(for: minimalTime)
      }
    }
  }

  private nonisolated func executeDataLoading(reload: Bool, onlyCached: Bool) async throws -> Data {
    let (onDeck, all) = try await service.getVideoList(reload: reload, onlyCached: onlyCached)

    Task { @MainActor in
      do {
        self.savedLastPlayed = try await self.storage.getLastPlayed()
      } catch {
        self.logger.error("Videos load error: \(error)")
        self.savedLastPlayed = nil
      }
    }

    try Task.checkCancellation()

    let videosById = Dictionary(all.map {
      ($0.video.id, $0)
    }, uniquingKeysWith: { one, _ in one })

    return Data(continueWatching: onDeck, videos: all, videosById: videosById)
  }

  public func load(silently: Bool, reload: Bool) async {
    loadingTask?.cancel()

    let task = load(\.data, silently: silently, priority: .userInitiated) { yield in
      do {
        if !reload, !self.data.isLoaded {
          let freshData = try await self.executeDataLoading(reload: reload, onlyCached: true)
          yield(.loaded(freshData))
        }

        let freshData = try await self.executeDataLoading(reload: reload, onlyCached: false)

        yield(.loaded(freshData))
      } catch is CancellationError {
        // NO-OP
      } catch {
        self.logger.error("Error: \(error)")
        throw error
      }
    }
    loadingTask = task
    return await task.value
  }

  public func getVideo(by id: Video.ID) -> VideoFromServer? {
    data.data?.videosById[id]
  }
}

public extension VideosDataSource {
  struct Data: Equatable, Sendable {
    public let continueWatching: [VideoFromServer]
    public let videos: [VideoFromServer]
    public let videosById: [Video.ID: VideoFromServer]
  }
}

public extension DependencyValues {
  var videosDataSource: VideosDataSource {
    get { self[VideosDataSourceKey.self] }
    set { self[VideosDataSourceKey.self] = newValue }
  }
}

private struct VideosDataSourceKey: DependencyKey {
  static var liveValue: VideosDataSource = .init()
}
