//
//  PlexVideoApp.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import Dependencies
import Foundation
import Inject
import PlexApi
import PlexCore
import PlexShared
import PlexUIKit
import SwiftUI
#if canImport(FirebaseCore)
  import FirebaseCore
#endif

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

  @Environment(\.videosViewModel)
  private var videosViewModel

  @Dependency(\.storage)
  private var storage

  @Dependency(\.requestorStorageProviding)
  private var requestorStorageProviding

  @Environment(\.currentVideoViewModel)
  private var currentVideoViewModel

  @ObserveInjection
  private var inject

  @ViewBuilder
  private var rootView: some View {
    RootView()
      .tint(PublicColor.plexTint)
      .accentColor(PublicColor.plexTint)
      .windowInjector()
      .enableInjection()
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

    func application(
      _: UIApplication,
      didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
      #if canImport(FirebaseCore)
        FirebaseApp.configure()
      #endif
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
    func applicationDidFinishLaunching(_: Notification) {
      #if canImport(FirebaseCore)
        FirebaseApp.configure()
      #endif
    }
  }
#endif
