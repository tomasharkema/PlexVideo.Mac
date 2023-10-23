//
//  ImageIO.swift
//
//
//  Created by Tomas Harkema on 17/10/2023.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

#if canImport(MobileCoreServices)
  import MobileCoreServices
#endif

#if os(macOS)
  import AppKit
#endif

enum ImageIO {
  static func resizedImage(at url: URL, for size: CGSize) -> PlexImage? {
    precondition(size != .zero)

    let options: [CFString: Any] = [
      kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height),
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
    ]

    guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
      let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
    else {
      return nil
    }

    return PlexImage(cgImage: image, size: size)
  }

  static func preloadImage(at url: URL, for size: CGSize) -> PlexImage? {
    guard let provider = CGDataProvider(url: url as CFURL) else {
      return nil
    }
    guard
      let image = CGImage(
        jpegDataProviderSource: provider,
        decode: nil,
        shouldInterpolate: true,
        intent: .defaultIntent
      )
    else {
      return nil
    }

    let width = Int(size.width)
    let height = Int(size.height)

    let colorSpace = CGColorSpaceCreateDeviceRGB()

    guard
      let imageContext = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue
          | CGImageAlphaInfo.premultipliedFirst
          .rawValue
      )
    else {
      return nil
    }

    imageContext.draw(image, in: .init(origin: .zero, size: CGSize(width: width, height: height)))

    guard let outputImage = imageContext.makeImage() else {
      return nil
    }

    return PlexImage(cgImage: outputImage, size: CGSize(width: width, height: height))
  }

  static func resizedImageWithHintingAndSubsampling(at url: URL, for size: CGSize) -> PlexImage? {
    guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(
        imageSource,
        0,
        nil
      ) as? [CFString: Any],
      let imageWidth = properties[kCGImagePropertyPixelWidth] as? CGFloat,
      let imageHeight = properties[kCGImagePropertyPixelHeight] as? CGFloat
    else {
      return nil
    }

    var options: [CFString: Any] = [
      kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height),
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceShouldCache: true,
      kCGImageSourceShouldCacheImmediately: true,
    ]

    if let uti = UTType(
      tag: url.pathExtension,
      tagClass: .filenameExtension,
      conformingTo: UTType.image
    ) {
      options[kCGImageSourceTypeIdentifierHint] = uti

      if uti == UTType.jpeg || uti == UTType.tiff || uti == UTType.png || uti == UTType.heif {
        switch min(imageWidth / size.width, imageHeight / size.height) {
        case ...2.0:
          options[kCGImageSourceSubsampleFactor] = 2.0

        case 2.0...4.0:
          options[kCGImageSourceSubsampleFactor] = 4.0

        case 4.0...:
          options[kCGImageSourceSubsampleFactor] = 8.0

        default:
          break
        }
      }
    }

    guard let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
    else {
      return nil
    }

    return PlexImage(cgImage: image, size: size)
  }
}
