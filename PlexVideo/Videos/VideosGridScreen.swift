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

  @Environment(VideosViewModel.self)
  private var videosViewModel: VideosViewModel
  
  @State
  private var gridViewModel = VideosGridScreenViewModel()
  
  @State
  private var searchText: String = ""

  @Binding
  private var video: Video?

  init(video: Binding<Video?>) {
    self._video = video
  }

  @ViewBuilder
  private var navigationBarElements: some View {
    HStack {
#if os(macOS)
      if case .loading = videosViewModel.data {
        ProgressView()
      } else {
        Button("Reload", action: {
          Task {
            await videosViewModel.load(silently: true)
          }
        })
      }
#endif
      Button("Logout", action: {
        gridViewModel.logout()
      })
    }
  }

  var body: some View {
    ScrollView {
      Group {
        switch videosViewModel.data {
        case .loaded(let data):
          VideosGrid()
            .padding()
            .animation(.easeInOut, value: data)
            .animation(.easeInOut, value: videosViewModel.searchResults)
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
      await videosViewModel.load(silently: true)
    }
    .task(id: searchText) {
      await self.videosViewModel.searchText(searchText)
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
