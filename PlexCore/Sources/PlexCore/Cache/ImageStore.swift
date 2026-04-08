//
//  ImageStore.swift
//
//
//  Created by Tomas Harkema on 17/10/2023.
//

import CryptoKit
import Dependencies
import Foundation
import OSLog
import PlexApi
import PlexShared
import Processed
import SwiftStacktrace

#if os(iOS)
  import UIKit
#endif

extension FileManager: @unchecked Sendable {}

struct ImageStore: Sendable {
  private let logger = Logger(subsystem: "PlexVideo", category: "ImageStore")

  static let shared = ImageStore()

  private let preparedImages = MemoryLimitedCache()
  private let localAssets: FileBasedCache
  private let fileManager: FileManager

  @Dependency(\.networkManager)
  private var networkManager

  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager

    // swiftlint:disable:next force_try
    let cachesDirectory = try! fileManager.url(
      for: .cachesDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    ).appendingPathComponent("asset-images", isDirectory: true)

    if !fileManager.fileExists(atPath: cachesDirectory.path) {
      // swiftlint:disable:next force_try
      try! fileManager.createDirectory(at: cachesDirectory, withIntermediateDirectories: true)
    }

    localAssets = FileBasedCache(directory: cachesDirectory)
  }

  func fetchByID(_ id: Asset.ID) -> Asset? {
    preparedImages.fetchByID(id)
  }

  private func fetchAsset(id: Asset.ID, url: URL) async throws {
    do {
      let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
      let (downloadUrl, response) = try await networkManager.session.download(for: request)

      try HTTPError.throwFor(urlResponse: response)

      let destPath = localAssets.url(forID: id)
      try FileManager.default.moveItem(at: downloadUrl, to: destPath)

    } catch {
      logger.error("Fetch Assets error: \(error)")
      throw error
    }
  }

  @RequestCacheActor
  private var requestsCache: [Asset.ID: Task<(asset: Asset, remote: Bool), any Error>] = [:]

  private func prepareAssetIfNeeded(
    id: Asset.ID,
    url: URL,
    size: CGSize
  ) async throws -> (asset: Asset, remote: Bool) {
    if let cached = await requestsCache[id] {
      return try await cached.value
    }

    let task = Task(priority: .high) {
      do {
        return try await prepareAsset(id: id, url: url, size: size)
      } catch {
        logger.error("prepareAssetIfNeeded error: \(error)")
        throw StacktraceError(error)
      }
    }

    Task(priority: .low) { @RequestCacheActor in
      requestsCache[id] = task
    }
    defer {
      Task(priority: .low) { @RequestCacheActor in
        requestsCache.removeValue(forKey: id)
      }
    }

    return try await task.value
  }

  private func prepareAsset(
    id: Asset.ID,
    url: URL,
    size: CGSize
  ) async throws -> (asset: Asset, remote: Bool) {
    //    let asset: Asset
    //    if let localAsset = localAssets.fetchByID(id) {
    //      asset = localAsset
    //    } else {
    //      try await fetchAsset(id: id, url: url)
    //      guard let remoteAsset = localAssets.fetchByID(id) else {
    //        throw NSError(domain: "asset not found", code: 69)
    //      }
    //      asset = remoteAsset
    //    }

    //    guard let preparedImage = asset.image.preparingForDisplay() else {
    //      throw AssetError.preparingImageFailed
    //    }

    let asset = localAssets.url(forID: id)

    let remote: Bool
    if !fileManager.fileExists(atPath: asset.path) {
      remote = true
      await Task.yield()
      try await fetchAsset(id: id, url: url)
      guard localAssets.fetchByID(id) != nil else {
        throw AssetError.assetNotFound
      }
      await Task.yield()
    } else {
      remote = false
    }

    //      let data = try Data(contentsOf: asset)
    #if os(iOS)
      let image = await UIImageReader.default.image(contentsOf: asset)?.preparingThumbnail(of: size)
    #elseif os(macOS)
      let image =
        ImageIO
        .resizedImageWithHintingAndSubsampling(
          at: asset,
          for: size
        )  // .preloadImage(at: asset, for: size)//.resizedImageWithHintingAndSubsampling(at: asset, for: size)
    #else
      #error("unsupported platform")
    #endif

    guard
      let image  // = asset.//ImageIO.resizedImageWithHintingAndSubsampling(at: asset, for:
    // size)?.preparingForDisplay()
    else {
      throw AssetError.assetNotFound
    }

    let prepared = Asset(id: id, image: image)
    Task(priority: .low) {
      self.preparedImages.add(asset: prepared)
    }

    return (asset: prepared, remote: remote)
  }

  func loadAssetByID(
    _ id: Asset.ID,
    _ url: URL,
    size: CGSize
  ) async throws -> (asset: Asset, remote: Bool) {
    try await prepareAssetIfNeeded(id: id, url: url, size: size)
  }
}

extension Video {
  var assetId: Asset.ID {
    SHA256.hash(data: Data(key.rawValue.utf8)).compactMap { String(format: "%02x", $0) }.joined()
  }
}

@globalActor
public actor RequestCacheActor {
  public static let shared = RequestCacheActor()
}
