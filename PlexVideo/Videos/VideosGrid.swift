//
//  VideosGrid.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import SwiftUI

let thumbSize = CGSize(width: 120, height: 180)

struct VideosGrid: View {
  @Binding var activeVideo: Video?

  let searchResults: [Video]?
  let continueWatching: [Video]
  let videos: [Video]
  let openVideo: (Video) -> Void

  private func section(text: String?, videos: [Video]) -> some View {
    Section(content: {
      ForEach(videos) { video in
        Button(
          action: {
            openVideo(video)
          },
          label: {
            VideoListItem(
              video: video,
              width: thumbSize.width,
              height: thumbSize.height,
              activeVideo: $activeVideo
            )
          }
        )
        .buttonStyle(PlainButtonStyle())
        .id((text ?? "") + video.id)
      }
    }, header: {
      if let text = text {
        Text(text).font(Font.system(size: 32, weight: .semibold, design: .default)).alignmentGuide(
          HorizontalAlignment.leading,
          computeValue: {
            $0[.leading]
          }
        )
      }
    })
  }

  var body: some View {
    LazyVGrid(columns: [
      GridItem(.adaptive(minimum: thumbSize.width), spacing: 10),
    ], spacing: 10) {
      if let searchResult = searchResults {
        section(text: nil, videos: searchResult)
      } else {
        section(text: "Continue Watching", videos: continueWatching)
        section(text: "All", videos: videos)
      }
    }
  }
}

struct VideosGrid_Preview: PreviewProvider {
  static var previews: some View {
    VideosGrid(activeVideo: .constant(nil), searchResults: nil, continueWatching: [
      Video.preview(id: "A"),
      Video.preview(),
      Video.preview(),
      Video.preview(),
      Video.preview(),
      Video.preview(),
    ], videos: [
      Video.preview(id: "A"),
      Video.preview(),
      Video.preview(),
      Video.preview(),
      Video.preview(),
      Video.preview(),
    ], openVideo: { _ in })
  }
}
