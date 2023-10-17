//
//  VideosGridScreen.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 10/06/2021.
//

import Foundation
import SwiftUI
import PlexApi
import PlexCore
import Inject
import PlexShared

@MainActor
struct VideosGridScreen: View {

  @Binding
  private var viewModel: VideosViewModel

  @State 
  private var searchText: String = ""

  @Binding
  private var video: Video?

  @State
  private var gridViewModel = VideosGridScreenViewModel()

  init(viewModel: Binding<VideosViewModel>, video: Binding<Video?>) {
    self._viewModel = viewModel
    self._video = video
  }

  @ViewBuilder
  private var navigationBarElements: some View {
    HStack {
      if case .loading = viewModel.data {
        ProgressView()
      } else {
        Button("Reload", action: {
          Task {
            await viewModel.load(silently: true)
          }
        })
      }
      Button("Logout", action: {
        gridViewModel.logout()
      })
    }
  }

  var body: some View {
    ScrollView {
      Group {
        switch viewModel.data {
        case .loaded(let data):
          VideosGrid(
            activeVideo: $video,
            viewModel: $viewModel,
            openVideo: { v in
              Task {
                let newVideo = try await viewModel.openVideo(video: v)
                withAnimation {
                  self.video = newVideo
                }
              }
            }
          )
          .padding()
          .animation(.easeInOut, value: data)
          .animation(.easeInOut, value: viewModel.searchResults)
          .animation(.easeInOut, value: searchText)
          
        case .loading:
          ProgressView()
          
        case .error(let error):
          Text(error.localizedDescription)
          
        case .absent:
          EmptyView()
          
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .refreshable {
      await viewModel.load(silently: true)
    }
    .task(id: searchText) {
      await self.viewModel.searchText(searchText)
    }
#if os(iOS)
    .searchable(text: $searchText, placement: .navigationBarDrawer)
#else
    .searchable(text: $searchText)
#endif
#if os(iOS)
    .navigationBarItems(trailing: navigationBarElements)
    .navigationBarTitle(Text("Videos"))
#endif
#if os(macOS)
    .navigationTitle("Videos")
    .toolbar {
      navigationBarElements
    }
#endif
  }
}

@MainActor @Observable
final class VideosGridScreenViewModel {
  @ObservationIgnored
  @Injected(\.storage)
  private var storage

  init() { }

  func logout() {
    storage.logout()
  }
}
