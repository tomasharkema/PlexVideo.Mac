//
//  ThumbViewModel.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Foundation
import PlexApi
import Inject
import PlexShared
import Processed
import Combine
import SwiftUI

@MainActor
@Observable
public final class ThumbViewModel: LoadableSupport {

  @MainActor
  private static var instanceCache = [VideoKey: ThumbViewModel]()

  public static nonisolated let thumbSize = CGSize(width: 120, height: 180)

  private let imageStore = ImageStore.shared

  @ObservationIgnored
  @Injected(\.api)
  private var api

  @ObservationIgnored
  @Injected(\.serverLocator)
  private var serverLocator

  @ObservationIgnored
  @Injected(\.storage)
  private var storage

  private let video: Video

  private var isLoadingTask: Task<Void, any Error>?
  public private(set) var image: PlexImage?

  @MainActor
  public static func get(for video: Video) -> ThumbViewModel {
    if let fromCache = instanceCache[video.key] {
      return fromCache
    }
    let newInstance = ThumbViewModel(video: video)
    instanceCache[video.key] = newInstance
    return newInstance
  }

  private init(video: Video) {
    self.video = video
    self.image = imageStore.fetchByID(video.assetId)?.image
  }

  public func start() async {
    do {
      if let isLoadingTask {
        return try await isLoadingTask.value
      }

      guard self.image == nil else {
        return
      }

      guard let root = serverLocator.connection, let token = storage.plexToken else {
        return
      }

      let task = Task {
        var size = ThumbViewModel.thumbSize
        size.width *= 2
        size.height *= 2

        let uuid = storage.uuid
        let url = self.api.imageUrl(
          root: root.uri,
          item: self.video,
          width: Int(size.width),
          height: Int(size.height),
          deviceInfo: DeviceInfo.current,
          uuid: uuid,
          token: token
        )

        let (asset, remote) = try await imageStore.loadAssetByID(video.assetId, url, size: size)

        let assetImage = asset.image

        guard assetImage != self.image else {
          return
        }

        let shouldAnimate = remote && self.image == nil

        if shouldAnimate {
          withTransaction(.init(animation: .easeInOut)) {
            self.image = assetImage
          }
        } else {
          self.image = assetImage
        }
      }

      isLoadingTask = task
      defer { isLoadingTask = nil }

      try await task.value

    } catch {
      print(error)
    }
  }
}
