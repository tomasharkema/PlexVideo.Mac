//
//  VideosGridScreen.swift
//
//
//  Created by Tomas Harkema on 10/06/2021.
//

import Dependencies
import Foundation
import PlexApi
import PlexCore
import PlexShared
import SwiftUI

@MainActor
public struct VideosGridScreen: View {
  @Environment(\.videosViewModel)
  private var videosViewModel: VideosViewModel

  @State
  private var searchText: String = ""

  public init() {}

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

  public var body: some View {
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
