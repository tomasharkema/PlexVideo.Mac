//
//  NavigationItem.swift
//
//
//  Created by Tomas Harkema on 20/10/2023.
//

import Foundation

public struct NavigationItem: Equatable, Hashable, Identifiable, Codable, Sendable {
  public let name: String
  public let image: String

  public var id: String {
    name
  }
}

public extension NavigationItem {
  static let home = NavigationItem(name: "Home", image: "house")
  static let servers = NavigationItem(name: "Servers", image: "server.rack")
  static let settings = NavigationItem(name: "Settings", image: "gearshape")

  static let menuItems: [NavigationItem] = [.home, .servers, .settings]
}
