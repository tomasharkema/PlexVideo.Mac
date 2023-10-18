//
//  VideoListItemn.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 06/06/2021.
//

import Foundation
import SwiftUI
import PlexShared
import PlexCore

@MainActor
struct VideoListItem: View {

  @Environment(CurrentVideoViewModel.self)
  private var currentVideoViewModel
  
  @State
  private var hovered = false

  let video: Video
//  let width: CGFloat
//  let height: CGFloat

  init(video: Video) {
    self.video = video
  }

//width: ThumbViewModel.thumbSize.width,
//height: ThumbViewModel.thumbSize.height

  @ViewBuilder
  private func progressOverlay() -> some View {
    VStack {
      Spacer()
      HStack {
        if let viewOffset = video.viewOffset?.value,
           let duration = video.media?.first?.duration.value
        {
          Rectangle()
            .foregroundColor(Color(.plexTint))
            .frame(
              width: ThumbViewModel.thumbSize.width *
              (CGFloat(viewOffset) /
               CGFloat(duration)),
              height: 5,
              alignment: .leading
            )
        }
        Spacer()
      }
      .background(Color.black.opacity(0.2))
      .frame(height: 5)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      Thumb(video: video)
        .overlay(progressOverlay())
        .cornerRadius(5.0)
        .shadow(radius: 10)
        .drawingGroup()

      Text(video.displayTitle)
        .font(.footnote)
        .fontWeight(.regular)
        .lineLimit(2, reservesSpace: true)
        .truncationMode(.tail)
        .dynamicTypeSize(.small)
        .shadow(radius: 10).padding(3)
    }
    .padding(5)
    .background(currentVideoViewModel.video?.key == video.key ? Color(.plexTint) : Color.clear)
    .background(hovered ? Color(.plexTint).opacity(0.6) : Color.clear)
    .cornerRadius(5)
    .onHover { h in
      withAnimation {
        hovered = h
      }
    }
  }
}

extension VideoListItem: Equatable {
  static nonisolated func == (lhs: Self, rhs: Self) -> Bool {
    lhs.video == rhs.video
  }
}

//struct VideoListItem_Preview: PreviewProvider {
//  static var previews: some View {
//    LazyVGrid(columns: [
//      GridItem(.adaptive(minimum: thumbSize.width), spacing: 10),
//    ], spacing: 10) {
//      ForEach(0 ..< 12) { _ in
//        VideoListItem(
//          video: Video.preview(),
//          width: thumbSize.width,
//          height: thumbSize.height,
//          activeVideo: .constant(Video.preview())
//        )
//      }
//    }
//  }
//}
