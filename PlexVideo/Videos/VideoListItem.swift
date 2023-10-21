//
//  VideoListItem.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 06/06/2021.
//

import Foundation
import SwiftUI
import PlexShared
import PlexCore
import PlexUIKit

@MainActor
struct VideoListItem: View {

  @Environment(CurrentVideoViewModel.self)
  private var currentVideoViewModel

  private let video: Video

  init(video: Video) {
    self.video = video
  }

  private func width(viewOffset: CGFloat, duration: CGFloat) -> CGFloat {
    ThumbViewModel.thumbSize.width * (viewOffset / duration)
  }

  @ViewBuilder
  private func progressBar() -> some View {
    if let viewOffset = video.viewOffset?.value, let duration = video.media?.first?.duration.value {
      Rectangle()
        .foregroundColor(PublicColor.plexTint)
        .frame(
          width: width(viewOffset: viewOffset, duration: duration),
          height: 5,
          alignment: .leading
        )
    }
  }

  @ViewBuilder
  private func progressOverlay() -> some View {
    VStack {
      Spacer()
      HStack {
        progressBar()
        Spacer()
      }
      .background(Color.black.opacity(0.2))
      .frame(height: 5)
    }
  }

  private var currentVideoBackground: Color {
    currentVideoViewModel.video?.key == video.key ? Color(PublicColor.plexTint) : Color.clear
  }

  var body: some View {
    VStack(alignment: .leading) {
      ZStack {
        Thumb(video: video)
        progressOverlay()
      }
      .cornerRadius(5)
      .frame(width: ThumbViewModel.thumbSize.width, height: ThumbViewModel.thumbSize.height)

      Text(video.displayTitle)
        .font(.body)
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
  static nonisolated func == (lhs: Self, rhs: Self) -> Bool {
    lhs.video == rhs.video
  }
}

#Preview(traits: .sizeThatFitsLayout) {
  VideoListItem(video: .preview())
    .environment(CurrentVideoViewModel())
    .preferredColorScheme(.dark)
    .previewLayout(.sizeThatFits)
}
