//
//  VideoListItemn.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 06/06/2021.
//

import Foundation
import SwiftUI
import PlexShared

struct VideoListItem: View {
  let video: Video
  let width: CGFloat
  let height: CGFloat

  @State var hovered = false
  @Binding var activeVideo: Video?

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
              width: width *
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
      Thumb(video: video, width: width, height: height)
        .overlay(progressOverlay())
        .cornerRadius(5.0)
//        .shadow(radius: 10)
      Text(video.displayTitle)
        .font(.footnote)
        .fontWeight(.regular)
        .lineLimit(1)
        .truncationMode(.tail)
        .dynamicTypeSize(.small)
//        .shadow(radius: 10).padding(3)
    }
    .padding(5)
    .background(activeVideo?.key == video.key ? Color(.plexTint) : Color.clear)
    .background(hovered ? Color(.plexTint).opacity(0.6) : Color.clear)
    .cornerRadius(5)
    .onHover { h in
      withAnimation {
        hovered = h
      }
    }
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
