//
//  DependencyInjector.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 17/10/2023.
//

import Foundation
import Inject
import PlexApi

final class DependencyInjector: ObservableObject {
  @Injected(\.storage)
  private var storage

  init() {
    InjectedValues.set(RequestorStorageProvidingKey.self, value: storage)
    InjectedValues.set(ServerLocatorStorageProvidingKey.self, value: storage)
    InjectedValues.set(AuthStorageProvidingKey.self, value: storage)
  }
}
