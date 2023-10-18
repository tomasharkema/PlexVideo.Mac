//
//  ImageUrlLoader.swift
//  
//
//  Created by Tomas Harkema on 17/10/2023.
//

import Foundation
import PlexApi
import Inject
import PlexShared
import Processed

//@MainActor
//public final class _ImageUrlLoader {
//
//  public static let shared = ImageUrlLoader()
//
//  struct State {
//    let root: Task<Connection?, Never>
//    let uuid: Task<String, Never>
//    let token: Task<String?, Never>
//  }
//
//  private var state: State?
//
//  @Injected(\.serverLocator)
//  private var serverLocator
//
//  @Injected(\.storage)
//  private var storage
//
//  private func getStateTask() -> State {
//    if let state {
//      return state
//    }
//
//    let rootTask = Task {
//      try? await serverLocator.root(force: false, deviceInfo: .current)
//    }
//
//    Task {
//      if await rootTask.value == nil {
//        try await Task.sleep(time: 1)
//        _ = getStateTask()
//      }
//    }
//
//    let uuid = Task { storage.uuid }
//    let token = Task { storage.plexToken }
//
//    let state = State(root: rootTask, uuid: uuid, token: token)
//    self.state = state
//    return state
//  }
//
//  func getInfo() async -> (root: Connection?, uuid: String, token: String?) {
//    let state = getStateTask()
//
//    return await (root: state.root.value, uuid: state.uuid.value, token: state.token.value)
//  }
//}
