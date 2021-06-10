//
//  VideosGrid.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import SwiftUI

struct VideosGrid: View {
  @StateObject var viewModel: VideosViewModel
  @State var searchText: String = ""
  @Binding var video: Video?

  private func section(text: String?, videos: [Video]) -> some View {
    Section(content: {
      ForEach(videos) { video in
        Button(
          action: {
            async {
              let newVideo = try await viewModel.openVideo(video: video)
              withAnimation {
                self.video = newVideo
              }
            }
          },
          label: {
            VideoListItem(video: video, width: 120, height: 180, activeVideo: $video)
          }
        )
        .buttonStyle(PlainButtonStyle())
      }
    }, header: {
      if let text = text {
      Text(text).font(Font.system(size: 32, weight: .semibold, design: .default))
      }
    })
  }

  @ViewBuilder
  private func content(_ data: Result<VideosViewModel.Data, ViewError>) -> some View {
    switch data {
    case let .success(data):
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 50) {
        if let searchResult = viewModel.searchResults {
          section(text: nil, videos: searchResult)
        } else {
          section(text: "Continue Watching", videos: data.continueWatching)
          section(text: "All", videos: data.videos)
        }
      }
    case let .failure(error):
      Text(error.localizedDescription)
    }
  }

  var body: some View {
    ScrollView {
      if let data = viewModel.data {
        content(data)
          .padding()
          .animation(.easeInOut, value: data)
          .animation(.easeInOut, value: viewModel.searchResults)
          .animation(.easeInOut, value: searchText)
          .navigationBarItems(trailing: HStack { Button("Reload", action: {
            async {
              try await viewModel.load()
            }
          })
          Button("Logout", action: {
            Storage.shared.plexToken = nil
          })
          })
          .navigationBarTitle(Text("Videos"))
      }
    }.refreshable {
      async {
        try await viewModel.load()
      }
    }
    .searchable(text: $searchText, placement: .navigationBarDrawer)
    .onChange(of: searchText, perform: { newText in
      async {
        await self.viewModel.searchText(newText)
      }
    })
  }
}
