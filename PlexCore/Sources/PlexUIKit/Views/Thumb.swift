//
//  Thumb.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import Inject
import PlexApi
import PlexCore
import PlexShared
import SwiftUI

@MainActor
public struct Thumb: View {
  @State
  private var viewModel: ThumbViewModel

  private let video: VideoFromServer
  private let size: CGSize

  public init(video: VideoFromServer, size: CGSize = ThumbViewModel.thumbSize) {
    self.video = video
    self.size = size
    _viewModel = .init(wrappedValue: ThumbViewModel.get(for: video))
  }

  @ViewBuilder
  private func image() -> some View {
    if let image = viewModel.image {
      Image(plexImage: image)
        .resizable()
        .aspectRatio(contentMode: .fill)
    } else {
      Color.black.opacity(0.6)
    }
  }

  public var body: some View {
    image()
      .frame(width: size.width, height: size.height)
      .clipped()
      .task {
        await viewModel.start()
      }
  }
}
