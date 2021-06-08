//
//  VideosGrid.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import SwiftUI

struct VideosGrid: View {
  @StateObject var viewModel: VideosViewModel

  @Binding var state: PlayerOverlay.ViewState

  private func section(text: String, videos: [Video]) -> some View {
    VStack(alignment: .leading) {
      Text(text).font(Font.system(size: 32, weight: .semibold, design: .default)).padding()

      LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 50) {
        ForEach(videos) { video in
          Button(
            action: {
              withAnimation {
                state = PlayerOverlay.ViewState(video: video, expanded: true)
              }
            },
            label: {
              VideoListItem(video: video, width: 120, height: 180, activeVideo: $state.video)
            }
          )
          .buttonStyle(PlainButtonStyle())
        }
      }
    }
  }

  var body: some View {
    ScrollView {
      if let data = viewModel.data {
        VStack(alignment: .leading) {
          section(text: "Continue Watching", videos: data.continueWatching)
          Spacer()
          section(text: "All", videos: data.videos)
        }
        .padding()
        .animation(.easeInOut(duration: 0.6), value: data)

        .navigationBarItems(trailing: Button("Reload", action: {
          asyncDetached {
            try await viewModel.load()
          }
        }))    .refreshable {
          asyncDetached {
            try await viewModel.load()
          }
        }
        .navigationBarTitle(Text("Videos"), displayMode: .inline)
      }
    }
  }
}
