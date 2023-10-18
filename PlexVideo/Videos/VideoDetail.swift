//
//  VideoDetail.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 05/06/2021.
//

#if canImport(UIKit)
import UIKit
#endif

import AVKit
import SwiftUI
import PlexApi
import PlexShared
import PlexCore

@MainActor
struct VideoDetail: View {
  
  @Environment(CurrentVideoViewModel.self)
  private var viewModel

  var body: some View {
    HStack {

      switch viewModel.player {
      case .absent:
        Rectangle().foregroundColor(.clear)

      case .loading:
        ProgressView()

      case .loaded(let player):
        if let video = viewModel.video {
#if os(iOS)
          VideoPlayer()
#elseif os(macOS)
          MacosVideoPlayerContainer()
#else
          BackupVideoPlayer()
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
    .task(id: viewModel.video) {
      await viewModel.load(video: viewModel.video)
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
    .task(id: viewModel.videoBounds) {
      await viewModel.updateBounds(bounds: viewModel.videoBounds)
    }
    .background(Color.black)
    .id(viewModel.video?.key)
  }
}
