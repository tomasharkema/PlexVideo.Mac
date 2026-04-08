//
//  VideoDetail.swift
//
//
//  Created by Tomas Harkema on 05/06/2021.
//

import AVKit
import PlexApi
import PlexCore
import PlexShared
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// @MainActor
struct VideoDetail: View {
  private var video: VideoFromServer

  @Environment(\.currentVideoViewModel)
  private var viewModel

  init(video: VideoFromServer) {
    self.video = video
  }

  var body: some View {
    HStack {
      switch viewModel.player {
      case .absent:
        Rectangle().foregroundColor(.clear)

      case .loading:
        ProgressView()

      case let .loaded(player):
#if os(iOS)
        VideoPlayer()
#elseif os(macOS)
        MacosVideoPlayerContainer()
#else
        BackupVideoPlayer()
#endif

      case let .error(error):
        EmptyView().alert(isPresented: .constant(true)) {
          Alert(title: Text(error.localizedDescription))
        }
      }
    }
    .task(id: viewModel.video) {
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
    .background(Color.black)
    .id(video.video.key)
  }
}
