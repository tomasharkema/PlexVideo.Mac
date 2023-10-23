//
//  VideoPlayer.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import AVKit
import Foundation
import PlexApi
import PlexCore
import PlexShared
import SwiftUI

#if os(iOS)
  struct VideoPlayer: UIViewControllerRepresentable {
    @Environment(CurrentVideoViewModel.self)
    private var viewModel

    init() {}

    func makeCoordinator() -> Coordinator {
      Coordinator {
        viewModel.isPip = $0
      } fullscreen: {
        viewModel.isFullscreen = $0
      }
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
      let vc = AVPlayerViewController()
      vc.canStartPictureInPictureAutomaticallyFromInline = true
      //    vc.entersFullScreenWhenPlaybackBegins = true
      vc.allowsPictureInPicturePlayback = true
      vc.updatesNowPlayingInfoCenter = true
      vc.player = viewModel.player.data!
      vc.delegate = context.coordinator
      //    vc.videoGravity = .resizeAspectFill
      vc.videoGravity = .resizeAspect
      vc.title = viewModel.video!.displayTitle

      //    player.addPeriodicTimeObserver(
      //      forInterval: CMTime(seconds: 10, preferredTimescale: 1),
      //      queue: .main,
      //      using: { [weak vc] _ in
      //        if videoBounds != vc?.videoBounds {
      //          videoBounds = vc?.videoBounds
      //        }
      //      }
      //    )

      Task { @MainActor in
        viewModel.isPip = false
        vc.player?.play()
        //      vc.perform(
        //        NSSelectorFromString("enterFullScreenAnimated:completionHandler:"),
        //        with: true,
        //        with: nil
        //      )
      }

      return vc
    }

    func updateUIViewController(_: AVPlayerViewController, context _: Context) {
      //    print("updateUIViewController")
    }

    static func dismantleUIViewController(
      _ uiViewController: AVPlayerViewController,
      coordinator _: Coordinator
    ) {
      uiViewController.allowsPictureInPicturePlayback = false
    }
  }

  extension VideoPlayer {
    final class Coordinator: NSObject, AVPlayerViewControllerDelegate {
      let pip: (Bool) -> Void
      let fullscreen: (Bool) -> Void

      init(pip: @escaping (Bool) -> Void, fullscreen: @escaping (Bool) -> Void) {
        self.pip = pip
        self.fullscreen = fullscreen
      }

      //    func playerViewControllerWillStartPictureInPicture(
      //      _ playerViewController: AVPlayerViewController
      //    ) {
      //      pip(true)
      //      playerViewController.videoGravity = .resizeAspect
      //    }
      //
      //    func playerViewControllerWillStopPictureInPicture(
      //      _ playerViewController: AVPlayerViewController
      //    ) {
      //      pip(false)
      //      playerViewController.videoGravity = .resizeAspectFill
      //    }

      //    func playerViewController(
      //      _: AVPlayerViewController,
      //      willBeginFullScreenPresentationWithAnimationCoordinator _:
      //      UIViewControllerTransitionCoordinator
      //    ) {
      //      fullscreen(true)
      ////      coordinator.animate(alongsideTransition: { _ in
      ////        playerViewController.videoGravity = .resizeAspect
      ////      }, completion: nil)
      //    }

      //    func playerViewController(
      //      _ playerViewController: AVPlayerViewController,
      //      willEndFullScreenPresentationWithAnimationCoordinator coordinator:
      //      UIViewControllerTransitionCoordinator
      //    ) {
      //      coordinator.animate(alongsideTransition: { _ in }, completion: {
      //        if $0.isCancelled {
      //          self.fullscreen(true)
      //          playerViewController.videoGravity = .resizeAspect
      //        } else {
      //          self.fullscreen(false)
      //          playerViewController.videoGravity = .resizeAspectFill
      //        }
      //      })
      //    }

      //    func playerViewControllerRestoreUserInterfaceForFullScreenExit(
      //      _: AVPlayerViewController
      //    ) async
      //      -> Bool
      //    {
      //      // Custom UI restoration logic
      //      true
      //    }
      //
      //    func playerViewControllerRestoreUserInterfaceForPictureInPictureStop(
      //      _: AVPlayerViewController
      //    ) async
      //      -> Bool
      //    {
      //      true
      //    }
    }
  }

#endif
