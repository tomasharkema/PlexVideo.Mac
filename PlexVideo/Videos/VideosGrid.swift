//
//  VideosGrid.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import SwiftUI
import PlexApi
import PlexCore
import PlexShared
import Processed

@MainActor
struct VideosGrid: View {

  @Environment(VideosViewModel.self)
  private var viewModel

  @Environment(CurrentVideoViewModel.self)
  private var currentVideoViewModel

//  let searchResults: LoadableState<[Video]>
//  public let continueWatching: [Video]
//  public let videos: [Video]
//  public let openVideo: (Video) -> Void

  init() { }

  private func section(text: String?, videos: [Video]) -> some View {
    Section(content: {
      ForEach(videos) { video in
        Button(
          action: {
            currentVideoViewModel.open(video: video)
          },
          label: {
            VideoListItem(
              video: video
            ).equatable()
          }
        )
        .buttonStyle(PlainButtonStyle())
        .id((text ?? "") + video.id)
      }
    }, header: {
      if let text = text {
        HStack {
          Text(text).foregroundColor(Color.white)
            .font(.title2.weight(.medium).smallCaps())
          Spacer()
        }
      }
    })
  }

  var body: some View {
    LazyVGrid(columns: [
      GridItem(.adaptive(minimum: ThumbViewModel.thumbSize.width), spacing: 10),
    ], spacing: 10) {

      switch viewModel.searchResults {
      case .absent:
        section(text: "Continue Watching", videos: viewModel.data.data?.continueWatching ?? [])
        section(text: "All", videos: viewModel.data.data?.videos ?? [])

      case .loading:
        ProgressView()

      case .loaded(let searchResult):
        section(text: nil, videos: searchResult)

      case .error(let error):
        Text(error.localizedDescription)
      }
    }
  }
}

//struct VideosGrid_Preview: PreviewProvider {
//  static var previews: some View {
//    VideosGrid(activeVideo: .constant(nil), searchResults: .absent, continueWatching: [
//      Video.preview(id: "A"),
//      Video.preview(),
//      Video.preview(),
//      Video.preview(),
//      Video.preview(),
//      Video.preview(),
//    ], videos: [
//      Video.preview(id: "A"),
//      Video.preview(),
//      Video.preview(),
//      Video.preview(),
//      Video.preview(),
//      Video.preview(),
//    ], openVideo: { _ in })
//  }
//}
