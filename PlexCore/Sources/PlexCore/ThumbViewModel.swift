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

@MainActor
public final class ImageUrlLoader {

  public static let shared = ImageUrlLoader()

  struct State {
    let root: Task<URL?, Never>
    let uuid: Task<String, Never>
    let token: Task<String?, Never>
  }

  private var state: State?

  @Injected(\.serverLocator)
  private var serverLocator

  @Injected(\.storage)
  private var storage

  private func getStateTask() -> State {
    if let state {
      return state
    } else {
      
      let rootTask = Task {
        try? await serverLocator.root(force: false, deviceInfo: .current)
      }
      
      let uuidTask = Task {
        storage.uuid
      }
      let tokenTask = Task {
        storage.plexToken
      }

      Task {
        if await rootTask.value == nil {
          try await Task.sleep(time: 1)
          _ = getStateTask()
        }
      }

      return State(root: rootTask, uuid: uuidTask, token: tokenTask)
    }
  }

  func getInfo() async -> (root: URL?, uuid: String, token: String?) {
    let state = getStateTask()

    return await (root: state.root.value, uuid: state.uuid.value, token: state.token.value)
  }
}


@Observable @MainActor
public final class ThumbViewModel: LoadableSupport {

  public static let thumbSize = CGSize(width: 120, height: 180)

  @ObservationIgnored
  @Injected(\.api)
  private var api

  @ObservationIgnored
  @Injected(\.imageCache)
  private var imageCache

  private let urlLoader = ImageUrlLoader.shared

  private let video: Video

  public private(set) var url: URL?

  public var width: CGFloat?
  public var height: CGFloat?

  public init(video: Video, width: CGFloat?, height: CGFloat?) {
    self.video = video
    self.width = width
    self.height = height
  }

  public func start() async {

    let info = await urlLoader.getInfo()
    let uuid = info.uuid

    guard let root = info.root,
          let token = info.token
    else {
      return
    }

//    do {
      if url == nil {
        url = imageCache.thumbCache[video.key]
      }
      
      url = self.api.imageUrl(
        root: root,
        item: self.video,
        width: Int(self.width ?? Self.thumbSize.width) * 2,
        height: Int(self.height ?? Self.thumbSize.height) * 2,
        deviceInfo: DeviceInfo.current,
        uuid: uuid, token: token
      )
//    } catch {
//      print(error)
//    }
  }
}
