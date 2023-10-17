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
  @Binding
  private var activeVideo: Video?

  @Binding
  private var viewModel: VideosViewModel

//  let searchResults: LoadableState<[Video]>
//  public let continueWatching: [Video]
//  public let videos: [Video]
  public let openVideo: (Video) -> Void

  init(activeVideo: Binding<Video?>, viewModel: Binding<VideosViewModel>, openVideo: @escaping (Video) -> Void) {
    self._activeVideo = activeVideo
    self._viewModel = viewModel
    self.openVideo = openVideo
  }

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
              width: ThumbViewModel.thumbSize.width,
              height: ThumbViewModel.thumbSize.height,
              activeVideo: $activeVideo
            )
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
