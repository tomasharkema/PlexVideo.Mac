//
//  Asset.swift
//
//
//  Created by Tomas Harkema on 17/10/2023.
//

import Foundation

struct Asset: Identifiable, Sendable {
  //  static let noAsset: Asset = Asset(
  //    id: "none", /*isPlaceholder: false,*/
  //    image: PlexImage(systemName: "airplane.circle.fill")!
  //  )

  var id: String
  //  var isPlaceholder: Bool

  var image: PlexImage

  func withImage(_ image: PlexImage) -> Asset {
    var this = self
    this.image = image
    return this
  }
}

extension PlexImage: @unchecked Sendable { }
