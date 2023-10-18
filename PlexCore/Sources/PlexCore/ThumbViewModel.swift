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

  public static let thumbSize = CGSize(width: 120, height: 180)

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

  public let initialImage: PlexImage?
  public private(set) var image: PlexImage?

  public init(video: Video) {
    self.video = video
    self.initialImage = imageStore.fetchByID(video.assetId)?.image
  }

  public func start() async {
    do {
      if let cachedAsset = imageStore.fetchByID(video.assetId) {
        image = cachedAsset.image
        return
      }

      let uuid = storage.uuid
      guard let root = serverLocator.connection, let token = storage.plexToken else {
        return
      }

      var size = ThumbViewModel.thumbSize
      size.width *= 2
      size.height *= 2

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

      withTransaction(remote ? .init(animation: .easeInOut) : .init()) {
        self.image = asset.image
      }

    } catch {
      print(error)
    }
  }
}
