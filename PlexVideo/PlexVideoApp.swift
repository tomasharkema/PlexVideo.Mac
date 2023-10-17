//
//  PlexVideoApp.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import SwiftUI
import Inject
import PlexShared

@MainActor
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
        ContentView(storage: storage)
          .accentColor(Color("plexTintColor"))
          .environment(\.mainWindowSize, proxy.size)
      }
    }
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
