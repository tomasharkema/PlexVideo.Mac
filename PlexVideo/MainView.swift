//
//  MainView.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 19/10/2023.
//

import Dependencies
import PlexApi
import PlexCore
import PlexShared
import PlexUIKit
import SwiftUI
#if canImport(SwiftUIIntrospect)
  import SwiftUIIntrospect
#endif
import PlexUIKit

@MainActor
struct MainView: View {
  @Environment(\.videosViewModel)
  private var viewModel

  @Dependency(\.serverLocator)
  private var serverLocator

  @State
  private var menuSelection: NavigationItem? = NavigationItem.home

  @AppStorage("menuSelection")
  private var menuSelectionIdentifier: String?

  @State
  private var logoutViewModel = LogoutViewModel()

  @State
  private var serversViewModel = ServersViewModel()

  @ViewBuilder
  private func navigationItem(_ item: NavigationItem) -> some View {
    NavigationLink(value: item) {
      HStack {
        Image(systemName: item.image)
        Text(item.name)
      }
    }
  }

  @ViewBuilder
  private var navigation: some View {
    ZStack(alignment: .top) {
      NavigationSplitView {
        SideMenu(menuSelection: $menuSelection)
        //          .background(.black)

      } detail: {
        switch menuSelection {
        case .some(.home), .none:
          VideosGridScreen()

        case .some(.settings):
          SettingsScreen(logoutHandler: {
            logoutViewModel.logout()
          })

        case .some(.servers):
          ServersScreen()
            .environment(serversViewModel)

        default:
          VideosGridScreen()
        }
      }
      .navigationSplitViewStyle(.balanced)
      #if os(macOS) && canImport(SwiftUIIntrospect)
        .introspect(.navigationSplitView, on: .macOS(.v14, .v13)) { controller in
          guard let splitViewController = (controller.delegate as? NSSplitViewController) else {
            return
          }

          for item in splitViewController.splitViewItems {
            item.canCollapse = false
            item.collapseBehavior = .preferResizingSiblingsWithFixedSplitView
          }
        }
      #endif

      ConnectionOverlay()
    }
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      navigation
      PlayerOverlay()
    }
    .task {
      await viewModel.load(silently: false, reload: false)
    }
    .onChange(of: menuSelectionIdentifier) {
      menuSelection = NavigationItem.menuItems.first {
        $0.id == menuSelectionIdentifier
      }
    }
    .onChange(of: menuSelection) {
      menuSelectionIdentifier = menuSelection?.id
    }
    .onAppear {
      menuSelection = NavigationItem.menuItems.first {
        $0.id == menuSelectionIdentifier
      }
    }
  }
}

// #Preview {
//  MainView()
//    .environment(VideosViewModel())
//    .environment(CurrentVideoViewModel())
// }
