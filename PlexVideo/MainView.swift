//
//  MainView.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 19/10/2023.
//

import SwiftUI
import PlexCore
import PlexUIKit
import Inject
import PlexApi
import PlexShared
import SwiftUIIntrospect

@MainActor
struct MainView: View {

  @Environment(VideosViewModel.self)
  private var viewModel

  @InjectedState(\.serverLocator)
  private var serverLocator

  @State
  private var menuSelection: NavigationItem? = NavigationItem.home

  @AppStorage("menuSelection")
  private var menuSelectionIdentifier: String?

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
//        .background(.black)
      } detail: {
        switch menuSelection {        
        case .some(.home), .none:
          VideosGridScreen()
        
        case .some(.settings):
          SettingsScreen()
//            .background(.black)

        case .some(.servers):
          ServersScreen(devices: serverLocator.devices, currentConnection: serverLocator.connection)

        default:
          VideosGridScreen()
//            .background(.black)
        }
      }
      .navigationSplitViewStyle(.balanced)
      .introspect(.navigationSplitView, on: .macOS(.v14, .v13)) { controller in
        (controller.delegate as? NSSplitViewController)?.splitViewItems.first?.canCollapse = false
      }

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

//#Preview {
//  MainView()
//    .environment(VideosViewModel())
//    .environment(CurrentVideoViewModel())
//}

//extension View {
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
//}
