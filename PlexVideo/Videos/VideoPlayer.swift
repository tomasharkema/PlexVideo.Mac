//
//  VideoPlayer.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import AVKit
import Foundation
import SwiftUI

struct VideoPlayer: UIViewControllerRepresentable {
  let video: Video
  let player: AVPlayer
  @Binding var isPip: Bool
  @Binding var isFullscreen: Bool
  @Binding var videoBounds: CGRect?

  class Coordinator: NSObject, AVPlayerViewControllerDelegate {
    let pip: (Bool) -> Void
    let fullscreen: (Bool) -> Void

    init(pip: @escaping (Bool) -> Void, fullscreen: @escaping (Bool) -> Void) {
      self.pip = pip
      self.fullscreen = fullscreen
    }

    func playerViewControllerWillStartPictureInPicture(
      _ playerViewController: AVPlayerViewController
    ) {
      pip(true)
      playerViewController.videoGravity = .resizeAspect
    }

    func playerViewControllerWillStopPictureInPicture(
      _ playerViewController: AVPlayerViewController
    ) {
      pip(false)
      playerViewController.videoGravity = .resizeAspectFill
    }

    func playerViewController(
      _ playerViewController: AVPlayerViewController,
      willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
    ) {
      fullscreen(true)
      coordinator.animate(alongsideTransition: { _ in
        playerViewController.videoGravity = .resizeAspect
      }, completion: nil)
    }

    func playerViewController(
      _ playerViewController: AVPlayerViewController,
      willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
    ) {
      coordinator.animate(alongsideTransition: { _ in }, completion: {
        if $0.isCancelled {
          self.fullscreen(true)
          playerViewController.videoGravity = .resizeAspect
        } else {
          self.fullscreen(false)
          playerViewController.videoGravity = .resizeAspectFill
        }
      })
    }

    func playerViewControllerRestoreUserInterfaceForFullScreenExit(_: AVPlayerViewController) async
      -> Bool
    {
      // Custom UI restoration logic
      return true
    }

    func playerViewControllerRestoreUserInterfaceForPictureInPictureStop(_ playerViewController: AVPlayerViewController) async -> Bool {
      return true
    }
  }

  func makeCoordinator() -> Coordinator {
    return Coordinator {
      isPip = $0
    } fullscreen: {
      isFullscreen = $0
    }
  }

  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let vc = AVPlayerViewController()
    vc.canStartPictureInPictureAutomaticallyFromInline = true
    vc.entersFullScreenWhenPlaybackBegins = true
    vc.allowsPictureInPicturePlayback = true
    vc.updatesNowPlayingInfoCenter = true
    vc.player = player
    vc.delegate = context.coordinator
    vc.videoGravity = .resizeAspectFill
    vc.title = video.displayTitle

//    player.addPeriodicTimeObserver(
//      forInterval: CMTime(seconds: 10, preferredTimescale: 1),
//      queue: .main,
//      using: { [weak vc] _ in
//        if videoBounds != vc?.videoBounds {
//          videoBounds = vc?.videoBounds
//        }
//      }
//    )

    DispatchQueue.main.async {
      isPip = false
      vc.player?.play()
      vc.perform(NSSelectorFromString("enterFullScreenAnimated:completionHandler:"), with: true, with: nil)
    }

    return vc
  }

  func updateUIViewController(_: AVPlayerViewController, context _: Context) {}

  static func dismantleUIViewController(
    _ uiViewController: AVPlayerViewController,
    coordinator _: Coordinator
  ) {
    uiViewController.allowsPictureInPicturePlayback = false
  }
}
