//
//  VideoDetail.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 05/06/2021.
//

import AVKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import PlexApi
import PlexShared
import PlexCore

@MainActor
struct VideoDetail: View {
  @State
  private var viewModel = VideoDetailViewModel()

  let video: Video?
  
  @Binding var isPip: Bool
  @Binding var isFullscreen: Bool
  @State var videoBounds: CGRect?

  var body: some View {
    HStack {

      switch viewModel.player {
      case .absent:
        Rectangle().foregroundColor(.clear)

      case .loading:
        ProgressView()

      case .loaded(let player):
        if let video {
#if os(iOS)
          VideoPlayer(
            video: video,
            player: player,
            isPip: $isPip,
            isFullscreen: $isFullscreen,
            videoBounds: $videoBounds
          )
#else
          BackupVideoPlayer(
            video: video,
            player: player
          )
#endif
        } else {
          EmptyView()
        }

      case .error(let error):
        EmptyView().alert(isPresented: .constant(true)) {
          Alert(title: Text(error.localizedDescription))
        }

      }
    }
    .task(id: video) {
      await viewModel.load(video: video)
    }
//    .onChange(of: isFullscreen) {
//      AppDelegate.orientationLock = $0 ? .landscape : .portrait
//      UIDevice.current.setValue(
//        $0 ? UIInterfaceOrientation.landscapeRight.rawValue : UIInterfaceOrientation
//          .portrait
//          .rawValue,
//        forKey: "orientation"
//      )
//    }
//    .onAppear {
//      AppDelegate.orientationLock = isFullscreen ? .landscape : .portrait
//      UIDevice.current.setValue(
//        isFullscreen ? UIInterfaceOrientation.landscapeRight
//          .rawValue : UIInterfaceOrientation
//          .portrait.rawValue,
//        forKey: "orientation"
//      )
//    }
//    .onDisappear {
//      AppDelegate.orientationLock = isFullscreen ? .landscape : .portrait
//      UIDevice.current.setValue(
//        isFullscreen ? UIInterfaceOrientation.landscapeRight
//          .rawValue : UIInterfaceOrientation
//          .portrait.rawValue,
//        forKey: "orientation"
//      )
//    }
    .task(id: videoBounds) {
      await viewModel.updateBounds(bounds: videoBounds)
    }
    .task(id: video) {
      await viewModel.load(video: video)
    }
    .background(Color.black)
    .id(video?.key)
  }
}
