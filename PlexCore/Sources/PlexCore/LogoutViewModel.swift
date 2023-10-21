//
//  LogoutViewModel.swift
//  
//
//  Created by Tomas Harkema on 17/10/2023.
//

import SwiftUI
import Inject

@MainActor @Observable
public final class LogoutViewModel {

  @ObservationIgnored
  @Injected(\.storage)
  private var storage

  public init() { }

  public func logout() {
    storage.logout()
  }
}
