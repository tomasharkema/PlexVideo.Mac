//
//  Thumb.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import SwiftUI
import PlexApi
import Inject
import PlexShared
import PlexCore
import CachedAsyncImage

struct Thumb: View {
  @State
  private var viewModel: ThumbViewModel

  private let video: Video
  private let width: CGFloat?
  private let height: CGFloat?

  @MainActor
  init(video: Video, width: CGFloat?, height: CGFloat?) {
    self.video = video
    self.width = width
    self.height = height
    self._viewModel = .init(wrappedValue: ThumbViewModel(video: video, width: width, height: height))
  }

  var body: some View {
        CachedAsyncImage(
          url: viewModel.url,
//          scale: 2,
          transaction: Transaction(animation: .linear(duration: 0.2)),
          content: { phase in
            if let image = phase.image {
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            } else if phase.error != nil {
              Color.red.opacity(0.3)
            } else {
              Color.black.opacity(0.6)//.overlay(ProgressView())
            }
          }
        )
    .frame(width: width, height: height)
    .task(id: video) {
      self.viewModel.width = width
      self.viewModel.height = height
      await viewModel.start()
    }
  }
}

struct VideoWidthHeight: Equatable {
  let video: Video
  let width: CGFloat?
  let height: CGFloat?
}

//struct Thumb_Preview: PreviewProvider {
//  static var previews: some View {
//    Thumb(
//      video: Video.preview(),
//      width: nil,
//      height: nil,
//      url: Video.preview().thumb.flatMap { URL(string: $0) }
//    )
//  }
//}
