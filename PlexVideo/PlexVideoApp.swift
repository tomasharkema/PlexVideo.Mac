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
import PlexCore
import PlexApi

@MainActor
@main
struct PlexVideoApp: App {

//  #if os(iOS)
//  @UIApplicationDelegateAdaptor(AppDelegate.self)
//  var appDelegate
//  #endif
  
  @State
  private var dependencyInjector = DependencyInjector()

  @State
  private var videosViewModel = VideosViewModel()

  @State
  private var currentVideoViewModel = CurrentVideoViewModel()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .tint(Color(.plexTint))
        .environment(videosViewModel)
        .environment(currentVideoViewModel)
        .environmentObject(dependencyInjector)
    }
  }
}

//#if os(iOS)
//class AppDelegate: NSObject, UIApplicationDelegate {
//  static var orientationLock = UIInterfaceOrientationMask.all
//
//  func application(
//    _: UIApplication,
//    supportedInterfaceOrientationsFor _: UIWindow?
//  ) -> UIInterfaceOrientationMask {
//    AppDelegate.orientationLock
//  }
//}
//#endif
