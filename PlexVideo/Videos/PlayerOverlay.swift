//
//  PlayerOverlay.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import PlexApi
import PlexCore
import PlexShared
import SwiftUI

@MainActor
struct PlayerOverlay: View {
  @Environment(\.font)
  private var font

  @Environment(CurrentVideoViewModel.self)
  private var viewModel

  @ViewBuilder
  private func videoView() -> some View {
    if let video = viewModel.video {
      VideoDetail(video: video)
    } else {
      EmptyView()
    }
  }

  @ViewBuilder
  private func videoOverlay() -> some View {
    HStack {
      HStack {
        Button(action: {
          viewModel.stopPlaying()
        }, label: {
          Image(systemName: "xmark")
            .foregroundColor(.white)
//            .font(font)
            .padding(10)
        })
        .buttonStyle(PlainButtonStyle())

//        Button(action: {
//          viewModel.fullscreen()
//        }, label: {
//          Image(systemName: "arrow.up.left.and.arrow.down.right")
//            .foregroundColor(.white)
//            .font(.title)
//            .padding(10)
//        })
//        .buttonStyle(PlainButtonStyle())
      }
    }
    .background(Color.black.opacity(0.6))
  }

  var body: some View {
    ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
      ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
        videoView()
        videoOverlay()
      }
      .cornerRadius(10)
      .padding(.bottom, 10)
      .frame(
        width: min(viewModel.screenWidth - 50, 400),
        height: viewModel.minHeight
      )
      .offset(y: viewModel.isPip ? min(viewModel.screenWidth - 50, 400) * 0.3 : 0)
      .animation(.easeInOut, value: viewModel.isPip)
    }
    .offset(y: viewModel.video == nil ? min(viewModel.screenWidth - 50, 400) : 0)
    .animation(.easeInOut, value: viewModel.video)
  }
}
