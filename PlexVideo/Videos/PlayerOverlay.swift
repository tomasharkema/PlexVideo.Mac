//
//  PlayerOverlay.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import SwiftUI
import PlexApi
import PlexShared

struct PlayerOverlay: View {
  @Binding private var video: Video?

  @State private var isPip = false
  @State private var isFullscreen = false

  @Environment(\.mainWindowSize)
  private var mainWindowSize

  init(video: Binding<Video?>) {
    self._video = video
  }

  private var screenWidth: CGFloat {
    mainWindowSize.width
  }

  @ViewBuilder
  private func videoView() -> some View {
    if let video {
      VideoDetail(video: video, isPip: $isPip, isFullscreen: $isFullscreen)
    } else {
      EmptyView()
    }
  }

  @ViewBuilder
  private func videoOverlay() -> some View {
    HStack {
      Button(action: {
        withAnimation {
          self.video = nil
        }
      }, label: {
        Image(systemName: "xmark")
          .foregroundColor(.white)
          .font(.title)
          .padding(10)
      })
      .buttonStyle(PlainButtonStyle())
    }
    .background(Color.black.opacity(0.6))
  }

  var body: some View {
    ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
      videoView()
        .overlay(
            videoOverlay(),
            alignment: Alignment(horizontal: .center, vertical: .top)
          )
          .cornerRadius(10)
        //        .shadow(radius: 10)
          .padding(.bottom, 10)
          .frame(
            width: min(screenWidth - 50, 400),
            height: min(screenWidth - 50, 400) * (1 / (video?.Media?.first?.aspectRatio?.value ?? (16 / 9)))
          )
          .offset(y: isPip ? min(screenWidth - 50, 400) * 0.3 : 0)
          .animation(.easeInOut, value: isPip)
    }
    .offset(y: video == nil ? min(screenWidth - 50, 400) : 0)
    .animation(.easeInOut, value: video)
  }
}
