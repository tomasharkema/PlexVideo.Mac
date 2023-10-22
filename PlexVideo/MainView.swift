//
//  MainView.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 19/10/2023.
//

import Inject
import PlexApi
import PlexCore
import PlexShared
import PlexUIKit
import SwiftUI
import SwiftUIIntrospect

@MainActor
struct MainView: View {
  @Environment(VideosViewModel.self)
  private var viewModel

  @InjectedObserving(\.serverLocator)
  private var serverLocator: ServerLocator

  @State
  private var menuSelection: NavigationItem? = NavigationItem.home

  @AppStorage("menuSelection")
  private var menuSelectionIdentifier: String?

  @State
  private var logoutViewModel = LogoutViewModel()

  @State
  private var pinger = ServerPinger()

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
          .background(.black)

      } detail: {
        switch menuSelection {
        case .some(.home), .none:
          VideosGridScreen()
            .background(.black)

        case .some(.settings):
          SettingsScreen(logoutHandler: {
            logoutViewModel.logout()
          })
          .background(.black)

        case .some(.servers):
          ServersScreen(
            servers: serverLocator.servers ?? [],
            currentConnection: serverLocator.connection,
            pings: pinger.pingsByConnection
          )
          .background(.black)
          .onAppear {
            pinger.startPinging()
          }
          .onDisappear {
            pinger.stopPinging()
          }

        default:
          VideosGridScreen()
            .background(.black)
        }
      }
      .navigationSplitViewStyle(.balanced)
      #if os(macOS)
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

// extension View {
//  public func introspectSplitView(customize: @escaping (NSSplitView) -> ()) -> some View {
//    return inject(AppKitIntrospectionView(
//      selector: { introspectionView in
//        guard let viewHost = Introspect.findViewHost(from: introspectionView) else {
//          return nil
//        }
//        return Introspect.findAncestorOrAncestorChild(ofType: NSSplitView.self, from: viewHost)
//      },
//      customize: customize
//    ))
//  }
// }
