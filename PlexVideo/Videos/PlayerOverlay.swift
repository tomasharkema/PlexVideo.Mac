//
//  PlayerOverlay.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import SwiftUI

struct PlayerOverlay: View {
  @Binding var video: Video?

  @State var isPip = false
  @State var isFullscreen = false

  var body: some View {
    ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
      VideoDetail(video: $video, isPip: $isPip, isFullscreen: $isFullscreen)
        .overlay(
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
          .background(Color.black.opacity(0.6)),

          alignment: Alignment(horizontal: .center, vertical: .top)
        )
        .cornerRadius(10)
        .shadow(radius: 10)
        .padding(.bottom, 10)
        .frame(
          width: min(UIScreen.main.bounds.width - 50, 400),
          height: min(UIScreen.main.bounds.width - 50, 400) * (1 /
            (video?.Media?.first?.aspectRatio?.value ?? (16 / 9)))
        )
        .offset(y: isPip ? min(UIScreen.main.bounds.width - 50, 400) * 0.3 : 0)
        .offset(y: video == nil ? min(UIScreen.main.bounds.width - 50, 400) : 0)
        .animation(.easeInOut, value: video)
        .animation(.easeInOut, value: isPip)
    }
  }
}
