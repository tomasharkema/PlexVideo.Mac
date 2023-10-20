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

@MainActor
struct Thumb: View {

  @State
  private var viewModel: ThumbViewModel

  private let video: Video

  init(video: Video) {
    self.video = video
    self._viewModel = .init(wrappedValue: ThumbViewModel.get(for: video))
  }

  @ViewBuilder
  private func image() -> some View {
    if let image = viewModel.image {
      Image(plexImage: image)
        .resizable()
        .aspectRatio(contentMode: .fill)
    } 
    else {
      Color.black.opacity(0.6)
    }
  }
  
  var body: some View {
    image()
      .frame(width: ThumbViewModel.thumbSize.width, height: ThumbViewModel.thumbSize.height)
      .clipped()
      .task {
        await viewModel.start()
      }
  }
}
