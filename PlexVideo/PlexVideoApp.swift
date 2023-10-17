//
//  PlexVideoApp.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import Foundation
import SwiftUI
import Inject
import PlexShared

@main
struct PlexVideoApp: App {

  #if os(iOS)
  @UIApplicationDelegateAdaptor(AppDelegate.self)
  var appDelegate
  #endif

  @Injected(\.storage)
  private var injectedStorage

  @State
  private var storage = Storage()

  init() {
    injectedStorage = storage
  }

  var body: some Scene {
    WindowGroup {
      GeometryReader { proxy in
        ContentView()
          .tint(Color(.plexTint))
          .environment(\.mainWindowSize, proxy.size)
      }
    }
//    .tint(Color(.plexTintColor))
  }
}

#if os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate {
  static var orientationLock = UIInterfaceOrientationMask.all

  func application(
    _: UIApplication,
    supportedInterfaceOrientationsFor _: UIWindow?
  ) -> UIInterfaceOrientationMask {
    AppDelegate.orientationLock
  }
}
#endif

private struct MainWindowSizeKey: EnvironmentKey {
  static let defaultValue: CGSize = .zero
}

extension EnvironmentValues {
  var mainWindowSize: CGSize {
    get { self[MainWindowSizeKey.self] }
    set { self[MainWindowSizeKey.self] = newValue }
  }
}
