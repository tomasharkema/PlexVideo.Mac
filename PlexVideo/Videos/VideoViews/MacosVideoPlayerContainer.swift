//
//  MacosVideoPlayerContainer.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 18/10/2023.
//

#if os(macOS)

  import AVKit
  import PlexCore
  import PlexShared
  import SwiftUI

  @MainActor
  struct MacosVideoPlayerContainer: View {
    @Environment(CurrentVideoViewModel.self)
    private var viewModel

    var body: some View {
      if let player = viewModel.player.data {
        MacosVideoPlayer(player: player)
      } else {
        ProgressView()
      }
    }
  }

  private struct MacosVideoPlayer: NSViewRepresentable {
    @Environment(CurrentVideoViewModel.self)
    private var viewModel

    private var player: AVPlayer

    init(player: AVPlayer) {
      self.player = player
    }

    func makeCoordinator() -> Coordinator {
      Coordinator {
        viewModel.isPip = $0
      } fullscreen: {
        viewModel.isFullscreen = $0
      }
    }

    func makeNSView(context: Context) -> AVPlayerView {
      let view = AVPlayerView()

      view.player = player
      view.showsFullScreenToggleButton = true
      view.allowsPictureInPicturePlayback = true
      view.updatesNowPlayingInfoCenter = true
      view.delegate = context.coordinator
      view.videoGravity = .resizeAspect

      return view
    }

    func updateNSView(_ view: AVPlayerView, context: Context) {
      //    print(context.coordinator.isFullscreen, viewModel.isFullscreen)

      if context.coordinator.isFullscreen != viewModel.isFullscreen {
        if viewModel.isFullscreen {
          Task { @MainActor in
            view.window?.toggleFullScreen(nil)

            //          view.safe
            //          let presOptions: NSApplication.PresentationOptions = [
            //            .autoHideMenuBar,
            //            .autoHideDock,
            //            .fullScreen
            //          ]
            //          view.enterFullScreenMode(NSScreen.main!, withOptions: [
            //            .fullScreenModeAllScreens: NSNumber(booleanLiteral: true)
            //            .fullScreenModeApplicationPresentationOptions:  NSNumber(value: presOptions.rawValue),
            //            .fullScreenModeSetting:
            //          ])
            //          view.videoGravity = .resizeAspectFill
          }
        } else {
          view.exitFullScreenMode()
        }
      }
    }

    @MainActor
    static func dismantleNSView(_ view: AVPlayerView, coordinator _: Coordinator) {
      view.exitFullScreenMode()
      view.allowsPictureInPicturePlayback = false
    }
  }

  extension MacosVideoPlayer {
    final class Coordinator: NSObject, AVPlayerViewDelegate {
      var isFullscreen = false
      let pip: (Bool) -> Void
      let fullscreen: (Bool) -> Void

      init(pip: @escaping (Bool) -> Void, fullscreen: @escaping (Bool) -> Void) {
        self.pip = pip
        self.fullscreen = fullscreen
      }

      func playerViewWillEnterFullScreen(_: AVPlayerView) {
        isFullscreen = true
        fullscreen(true)
      }

      func playerViewWillExitFullScreen(_: AVPlayerView) {
        isFullscreen = false
        fullscreen(false)
      }
    }
  }

#endif
