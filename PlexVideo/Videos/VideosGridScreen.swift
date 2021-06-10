//
//  VideosGridScreen.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 10/06/2021.
//

import Foundation
import SwiftUI

struct VideosGridScreen: View {
  @StateObject var viewModel: VideosViewModel
  @State var searchText: String = ""
  @Binding var video: Video?

  @ViewBuilder
  private func content(_ data: Result<VideosViewModel.Data, ViewError>) -> some View {
    switch data {
    case let .success(data):
      VideosGrid(
        activeVideo: $video,
        searchResults: viewModel.searchResults,
        continueWatching: data.continueWatching,
        videos: data.videos,
        openVideo: { v in
          async {
            let newVideo = try await viewModel.openVideo(video: v)
            withAnimation {
              self.video = newVideo
            }
          }
        }
      )
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
