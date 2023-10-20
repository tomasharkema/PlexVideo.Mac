//
//  PlexImage.swift
//
//
//  Created by Tomas Harkema on 17/10/2023.
//

#if os(iOS)
import UIKit
import SwiftUI

public typealias PlexImage = UIImage

extension Image {
  public init(plexImage: PlexImage) {
    self.init(uiImage: plexImage)
  }
}

extension PlexImage {
  public convenience init(cgImage: CGImage, size: CGSize) {
    self.init(cgImage: cgImage)
  }
}
#endif

#if os(macOS)
import AppKit
import SwiftUI

public typealias PlexImage = NSImage

extension Image {
  public init(plexImage: PlexImage) {
    self.init(nsImage: plexImage)
  }
}

extension PlexImage {
  public convenience init?(systemName name: String) {
    self.init(systemSymbolName: name, accessibilityDescription: nil)
  }

  func preparingForDisplay() -> NSImage? {
    return self
  }

  func preparingThumbnail(of size: CGSize) -> NSImage? {
    return self//ImageIO.resizedImageWithHintingAndSubsampling(at: asset, for: size)
  }
}

#endif
