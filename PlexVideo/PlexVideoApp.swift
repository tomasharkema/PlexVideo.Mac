//
//  PlexVideoApp.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import Foundation
import Inject
import PlexApi
import PlexCore
import PlexShared
import PlexUIKit
import SwiftUI
import FirebaseCore

@MainActor
@main
struct PlexVideoApp: App {
  #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate
  #endif

  #if os(macOS)
  @NSApplicationDelegateAdaptor(AppDelegate.self) 
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
      .tint(PublicColor.plexTint)
      .accentColor(PublicColor.plexTint)
      .environment(videosViewModel)
      .environment(currentVideoViewModel)
      .environmentObject(dependencyInjector)
      .windowInjector()

    //      .environment(\.font, .plex)
  }

  var body: some Scene {
    #if os(macOS)

      Window("Videos", id: "videos") {
        rootView.frame(minWidth: 700)
      }
      .windowResizability(.contentMinSize)
//      .windowStyle(.hiddenTitleBar)

    #else
      WindowGroup {
        rootView
      }
    #endif

    #if os(macOS)
      MenuBarExtra("PlexVideo", systemImage: "recordingtape.circle") {
        if let video = currentVideoViewModel.video {
          Text("Now playing: \(video.video.title)")
          Divider()
        }
        LoadingButton(
          text: { Image(systemName: "arrow.clockwise") },
          loadingText: { ProgressView().controlSize(.small) }
        ) {
          await videosViewModel.reload(silently: true)
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

extension Font {
  static let plex = Font.custom("PlexeinaRegular", size: 14, relativeTo: .body)
  static let plexBold = Font.custom("PlexeinaBold", size: 14, relativeTo: .body)
}

#if os(iOS)
  final class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      FirebaseApp.configure()
      return true
    }

    func application(
      _: UIApplication,
      supportedInterfaceOrientationsFor _: UIWindow?
    ) -> UIInterfaceOrientationMask {
      AppDelegate.orientationLock
    }
  }
#endif

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    FirebaseApp.configure()
  }
}
#endif
