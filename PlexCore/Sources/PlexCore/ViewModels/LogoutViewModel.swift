//
//  LogoutViewModel.swift
//
//
//  Created by Tomas Harkema on 17/10/2023.
//

import Dependencies
import SwiftUI

@MainActor @Observable
public final class LogoutViewModel {
  @ObservationIgnored
  @Dependency(\.storage)
  private var storage

  public init() {}

  public func logout() {
    storage.logout()
  }
}
