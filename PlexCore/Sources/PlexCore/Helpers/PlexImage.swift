//
//  PlexImage.swift
//
//
//  Created by Tomas Harkema on 17/10/2023.
//

#if os(iOS)
  import SwiftUI
  import UIKit

  public typealias PlexImage = UIImage

  public extension Image {
    init(plexImage: PlexImage) {
      self.init(uiImage: plexImage)
    }
  }

  public extension PlexImage {
    convenience init(cgImage: CGImage, size _: CGSize) {
      self.init(cgImage: cgImage)
    }
  }
#endif

#if os(macOS)
  import AppKit
  import SwiftUI

  public typealias PlexImage = NSImage

  public extension Image {
    init(plexImage: PlexImage) {
      self.init(nsImage: plexImage)
    }
  }

  extension PlexImage {
    public convenience init?(systemName name: String) {
      self.init(systemSymbolName: name, accessibilityDescription: nil)
    }

    func preparingForDisplay() -> NSImage? {
      self
    }

    func preparingThumbnail(of _: CGSize) -> NSImage? {
      self // ImageIO.resizedImageWithHintingAndSubsampling(at: asset, for: size)
    }
  }

#endif
