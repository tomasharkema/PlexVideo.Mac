//
//  VideoListItem.swift
//
//
//  Created by Tomas Harkema on 06/06/2021.
//

import Foundation
import PlexCore
import PlexShared
import SwiftUI

@MainActor
struct VideoListItem: View {
  @Environment(\.currentVideoViewModel)
  private var currentVideoViewModel

  private let video: VideoFromServer

  init(video: VideoFromServer) {
    self.video = video
  }

  private func width(viewOffset: CGFloat, duration: CGFloat) -> CGFloat {
    ThumbViewModel.thumbSize.width * (viewOffset / duration)
  }

  private var currentVideoBackground: Color {
    currentVideoViewModel.video?.video.key == video.video.key
      ? Color(PublicColor.plexTint) : Color.clear
  }

  var body: some View {
    VStack(alignment: .leading) {
      ZStack {
        Thumb(video: video)
        VStack {
          Spacer()
          ProgressBar(video: video.video)
        }
      }
      .cornerRadius(5)
      .frame(width: ThumbViewModel.thumbSize.width, height: ThumbViewModel.thumbSize.height)

      Text(video.video.displayTitle)
        .fontWeight(.regular)
        .lineLimit(2, reservesSpace: true)
        .truncationMode(.tail)
        .padding(3)
    }
    .frame(width: ThumbViewModel.thumbSize.width)
    .padding(5)
    .background(currentVideoBackground)
    //    .background(hoveredVideoBackground)
    .cornerRadius(5)
    .drawingGroup()
    //    .compositingGroup()
  }
}

extension VideoListItem: Equatable {
  nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.video == rhs.video
  }
}

// #Preview(traits: .sizeThatFitsLayout) {
//  VideoListItem(video: .preview())
//    .environment(CurrentVideoViewModel())
//    .preferredColorScheme(.dark)
//    .previewLayout(.sizeThatFits)
// }
