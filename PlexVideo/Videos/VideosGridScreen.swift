//
//  VideosGridScreen.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 10/06/2021.
//

import Foundation
import Inject
import PlexApi
import PlexCore
import PlexShared
import PlexUIKit
import SwiftUI

@MainActor
struct VideosGridScreen: View {
  @Environment(VideosViewModel.self)
  private var videosViewModel: VideosViewModel

  @State
  private var searchText: String = ""

  @ToolbarContentBuilder
  private var navigationBarElements: some ToolbarContent {
    ToolbarItemGroup {
      #if os(macOS) || targetEnvironment(macCatalyst)
        LoadingButton(
          text: { Image(systemName: "arrow.clockwise") },
          loadingText: { ProgressView().controlSize(.small) }
        ) {
          await videosViewModel.reload(silently: true)
        }
        .keyboardShortcut("r", modifiers: .command)
      #endif
    }
  }

  @ViewBuilder
  private var innerScrollview: some View {
    switch videosViewModel.data {
    case .loaded:
      VideosGrid()

    case .loading, .absent:
      ProgressView()

    case let .error(error):
      Text(error.localizedDescription)
    }
  }

  var body: some View {
    ScrollView {
      innerScrollview
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .task(id: searchText) {
      await videosViewModel.searchText(searchText)
    }
    .animation(.easeInOut, value: videosViewModel.data)
    .animation(.easeInOut, value: videosViewModel.searchResults)
    .animation(.easeInOut, value: searchText)
    .navigationTitle("Videos")
    #if !targetEnvironment(macCatalyst)
      .refreshable {
        await videosViewModel.reload(silently: true)
      }
    #endif
    #if os(iOS)
    .searchable(text: $searchText, placement: .navigationBarDrawer)
    #else
    .searchable(text: $searchText, placement: .toolbar)
    #endif
    #if os(macOS)
    .toolbar {
      navigationBarElements
    }
    #endif
  }
}
