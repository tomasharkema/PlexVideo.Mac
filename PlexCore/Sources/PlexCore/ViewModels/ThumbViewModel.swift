//
//  ThumbViewModel.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 16/10/2023.
//

import Combine
import Foundation
import Inject
import OSLog
import PlexApi
import PlexShared
import Processed
import SwiftUI

@MainActor
@Observable
public final class ThumbViewModel: LoadableSupport {
  private let logger = Logger(subsystem: "PlexVideo", category: "ThumbViewModel")

  @MainActor
  private static var instanceCache = [VideoFromServer.ID: ThumbViewModel]()

  public nonisolated static let thumbSize = CGSize(width: 120, height: 180)

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

  private let video: VideoFromServer

  private var isLoadingTask: Task<Void, any Error>?
  public private(set) var image: PlexImage?

  @MainActor
  public static func get(for video: VideoFromServer) -> ThumbViewModel {
    if let fromCache = instanceCache[video.id] {
      return fromCache
    }
    let newInstance = ThumbViewModel(video: video)
    instanceCache[video.id] = newInstance
    return newInstance
  }

  private init(video: VideoFromServer) {
    self.video = video
    image = imageStore.fetchByID(video.video.assetId)?.image
  }

  public func start() async {
    do {
      if let isLoadingTask {
        return try await isLoadingTask.value
      }

      guard image == nil else {
        return
      }

      guard let token = storage.plexToken else {
        return
      }

      let task = Task {
        var size = ThumbViewModel.thumbSize
        size.width *= 2
        size.height *= 2

        let uuid = storage.uuid
        let url = self.api.imageUrl(
          item: self.video,
          width: Int(size.width),
          height: Int(size.height),
          uuid: uuid,
          token: token
        )

        let (asset, remote) = try await imageStore.loadAssetByID(
          video.video.assetId,
          url,
          size: size
        )

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
      logger.error("Thumb error: \(error)")
    }
  }
}
