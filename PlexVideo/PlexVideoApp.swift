//
//  PlexVideoApp.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import SwiftUI

@main
struct PlexVideoApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  var body: some Scene {
    WindowGroup {
      ContentView()
        .accentColor(Color.tint)
    }
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  static var orientationLock = UIInterfaceOrientationMask
    .all // By default you want all your views to rotate freely

  func application(_: UIApplication,
                   supportedInterfaceOrientationsFor _: UIWindow?) -> UIInterfaceOrientationMask
  {
    return AppDelegate.orientationLock
  }
}
