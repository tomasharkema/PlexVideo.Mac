//
//  SideMenu.swift
//
//
//  Created by Tomas Harkema on 20/10/2023.
//

import SwiftUI

public struct SideMenu: View {
    
  @Binding 
  private var menuSelection: NavigationItem?

  public init(menuSelection: Binding<NavigationItem?>) {
    self._menuSelection = menuSelection
  }

  @ViewBuilder
  private func navigationItem(_ item: NavigationItem) -> some View {
    NavigationLink(value: item) {
      HStack {
        Image(systemName: item.image)
        Text(item.name)
      }
    }
  }

  public var body: some View {
    List(selection: $menuSelection) {
      Section("Menu") {
        ForEach(NavigationItem.menuItems) { item in
          navigationItem(item)
        }
      }
    }
    .listStyle(.sidebar)
  }
}
