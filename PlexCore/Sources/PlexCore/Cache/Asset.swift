//
//  Asset.swift
//
//
//  Created by Tomas Harkema on 17/10/2023.
//

import Foundation

struct Asset: Identifiable, Sendable {
  let id: String

  private(set) var image: PlexImage

  func withImage(_ image: PlexImage) -> Asset {
    var this = self
    this.image = image
    return this
  }
}

extension PlexImage: @unchecked Sendable {}
