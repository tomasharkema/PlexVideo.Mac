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
import PlexUIKit

@MainActor
@main
struct PlexVideoApp: App {

  #if os(iOS)
  @UIApplicationDelegateAdaptor(AppDelegate.self)
  private var appDelegate
  #endif
  
  @Environment(\.scenePhase) 
  private var scenePhase

  @State
  private var dependencyInjector = DependencyInjector()

  @State
  private var videosViewModel = VideosViewModel()

  @State
  private var currentVideoViewModel = CurrentVideoViewModel()

  @ViewBuilder
  private var rootView: some View {
    RootView()
      .tint(Color(.plexTint))
      .accentColor(.plexTint)
      .environment(videosViewModel)
      .environment(currentVideoViewModel)
      .environmentObject(dependencyInjector)
  }

  var body: some Scene {
#if os(macOS)

    Window("Videos", id: "videos") {
      rootView
    }
    .windowStyle(.hiddenTitleBar)
    
#else
    WindowGroup {
      rootView
    }
#endif

#if os(macOS)
    MenuBarExtra("PlexVideo", systemImage: "recordingtape.circle") {
      if let video = currentVideoViewModel.video {
          Text("Now playing: \(video.title)")
        Divider()
      }
      LoadingButton(
        text: { Image(systemName: "arrow.clockwise") },
        loadingText: { ProgressView().controlSize(.small) }
      ) {
        await self.videosViewModel.reload(silently: true)
      }
      .keyboardShortcut("r")

      Divider()

      Button("Quit") {
        NSApplication.shared.terminate(nil)
      }
      .keyboardShortcut("q")
    }
#endif
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
