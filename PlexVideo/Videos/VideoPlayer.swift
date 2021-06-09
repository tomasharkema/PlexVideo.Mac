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
  let player: AVPlayer
  @Binding var isPip: Bool
  @Binding var videoBounds: CGRect?

  class Coordinator: NSObject, AVPlayerViewControllerDelegate {
    let pip: (Bool) -> Void

    init(pip: @escaping (Bool) -> Void) {
      self.pip = pip
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
      coordinator.animate(alongsideTransition: { _ in
        playerViewController.videoGravity = .resizeAspect
      }, completion: nil)
    }

    func playerViewController(
      _ playerViewController: AVPlayerViewController,
      willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
    ) {
      coordinator.animate(alongsideTransition: { _ in
        playerViewController.videoGravity = .resizeAspectFill
      }, completion: nil)
    }

    func playerViewControllerRestoreUserInterfaceForFullScreenExit(_: AVPlayerViewController) async
      -> Bool
    {
      // Custom UI restoration logic
      return false
    }

    
  }

  func makeCoordinator() -> Coordinator {
    return Coordinator {
      isPip = $0
    }
  }

  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let vc = AVPlayerViewController()
    vc.canStartPictureInPictureAutomaticallyFromInline = true
    vc.entersFullScreenWhenPlaybackBegins = true
    vc.updatesNowPlayingInfoCenter = true
    vc.player = player
    vc.delegate = context.coordinator
    vc.videoGravity = .resizeAspectFill

    player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 10, preferredTimescale: 1), queue: .main, using: { [weak vc] time in
      if videoBounds != vc?.videoBounds {
        videoBounds = vc?.videoBounds
      }
    })

    DispatchQueue.main.async {
      isPip = false
      vc.player?.play()
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
