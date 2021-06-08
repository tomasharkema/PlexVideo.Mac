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

  @Binding var pip: Bool

  class Coordinator: NSObject, AVPlayerViewControllerDelegate {
    let pip: (Bool) -> Void

    init(pip: @escaping (Bool) -> Void) {
      self.pip = pip
    }

    func playerViewControllerWillStartPictureInPicture(_: AVPlayerViewController) {
      pip(true)
    }

    func playerViewControllerWillStopPictureInPicture(_: AVPlayerViewController) {
      pip(false)
    }
  }

  func makeCoordinator() -> Coordinator {
    return Coordinator(pip: {
      pip = $0
    })
  }

  func makeUIViewController(context: Context) -> some UIViewController {
    let vc = AVPlayerViewController()
    vc.player = player
    vc.delegate = context.coordinator
    return vc
  }

  func updateUIViewController(_: UIViewControllerType, context _: Context) {}
}
