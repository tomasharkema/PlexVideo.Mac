//
//  MemoryLimitedCache.swift
//
//
//  Created by Tomas Harkema on 17/10/2023.
//

import Combine
import ConcurrencyExtras
import Foundation
import os
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#endif

// swiftlint:disable shorthand_operator

extension Measurement where UnitType: Dimension {
  static var zero: Self {
    .init(value: 0.0, unit: UnitType.baseUnit())
  }
}

// Cache that tries to stay under a fixed memory limit.
final class MemoryLimitedCache: Cache, Sendable {
  let memoryLimit: Measurement<UnitInformationStorage>
  private(set) var currentMemoryUsage = Measurement<UnitInformationStorage>.zero

  // private let accessLock = UnfairLock()
  private var assets =
    LockIsolated([Asset.ID: Asset]()) //: [Asset.ID: Asset] = [:] // GuardedBy(accessLock)
  private var protectedAssetIDs: [Asset.ID: Int] = [:] // GuardedBy(accessLock)
  private var cancellation = [AnyCancellable]()

  private let logger: Logger
  private let signposter: OSSignposter

  // The default memory limit is 320 MB, which is very large. This is because there are
  // incredibly large assets for demonstration purposes. Rely on the Image resizing APIs
  // to scale images to the size needed and to save memory.
  init(
    limit: Measurement<UnitInformationStorage> = .init(value: 320, unit: .megabytes),
    logger: Logger = .default,
    signposter: OSSignposter? = nil
  ) {
    memoryLimit = limit
    self.logger = logger
    self.signposter = signposter ?? OSSignposter(logger: logger)

// Purge everything when app is under memory pressure.
#if os(iOS)
    Task { @MainActor in
      NotificationCenter.default
        .publisher(for: UIApplication.didReceiveMemoryWarningNotification)
        .sink { [weak self] _ in self?.purge() }
        .store(in: &cancellation)
    }
#endif
  }

  func fetchByID(_ id: Asset.ID) -> Asset? {
    assets.withValue { assets in
      assets[id]
    }
  }

  // Asset with `id` will have its retention priority increased by 1 until `.cancel` is called.
  // - Returns: Cancellable which will decrease the priority by 1.
  //  func takeAssertionForID(_ id: Asset.ID) -> AnyCancellable? {
  //    let lock = self.accessLock.acquire()
  //    defer { lock.cancel() }
  //
  //    guard self.assets[id] != nil else { return nil }
  //
  //    let signpostID = signposter.makeSignpostID()
  //    let interval = signposter.beginInterval("Assertion", id: signpostID, "id=\(id, attributes:
  //    "name=id")")
  //
  //    protectedAssetIDs[id, default: 0] += 1
  //    return AnyCancellable { [weak self] in
  //      guard let self = self else { return }
  //      self.accessLock.withLock {
  //        guard var retainCount = self.protectedAssetIDs[id] else { return }
  //        retainCount -= 1
  //        // Passing nil to remove the id from `protectedAssetID`.
  //        self.protectedAssetIDs[id] = retainCount > 0 ? retainCount : nil
  //      }
  //      self.signposter.endInterval("Assertion", interval)
  //    }
  //  }

  func add(asset: Asset) {
    //    guard !asset.isPlaceholder else {
    //      logger.notice("Placeholder (\(asset.id)) was sent to MemoryLimitedCache - Rejecting.")
    //      return
    //    }

    let estimatedMemory = estimatedMemory(of: asset)
    signposter.emitEvent("AddAsset", "assetID=\(asset.id) memoryUsage=\(estimatedMemory)")
    assets.withValue { assets in
      // Remove the current asset if it exists.
      if let currentAsset = assets.removeValue(forKey: asset.id) {
        currentMemoryUsage = currentMemoryUsage - self.estimatedMemory(of: currentAsset)
      }
      if (currentMemoryUsage + estimatedMemory) >= memoryLimit {
        self._locked_purge(atLeast: estimatedMemory)
      }
      assets[asset.id] = asset

      currentMemoryUsage = currentMemoryUsage + estimatedMemory
    }
  }

  func purge(atLeast amount: Measurement<UnitInformationStorage>? = nil) {
    assets.withValue { _ in
      _locked_purge(atLeast: amount)
    }
  }

  /// Estimates the cost of an image as `Width*Height*Channels`.
  /// - note: Image memory cost can vary depending on the image and only *preparedImages* are safe
  /// to estimate this way.
  func estimatedMemory(of asset: Asset) -> Measurement<UnitInformationStorage> {
    let image = asset.image
    return Measurement(
      value: Double(image.size.width * image.size.height * 3),
      unit: UnitInformationStorage.bytes
    )
  }

  private func _locked_purge(atLeast amount: Measurement<UnitInformationStorage>?) {
    let interval = signposter.beginInterval(
      "Purge",
      "amount=\(amount?.formatted() ?? "<all>", attributes: "name=amount")"
    )
    defer { signposter.endInterval("Purge", interval, "newCount=\(self.assets.count)") }

    guard var amountToGo = amount, amountToGo < currentMemoryUsage else {
      assets.withValue { assets in
        assets.removeAll()
      }
      currentMemoryUsage = .zero
      return
    }

    // Delete non-protected IDs first and then go through the others.
    let weightedKeys = assets.keys
      .map {
        ($0, self.protectedAssetIDs[$0, default: 0])
      }
      .sorted(by: { $0.1 < $1.1 })
      .map(\.0)

    for id in weightedKeys {
      guard amountToGo > .zero else { break }
      assets.withValue { assets in
        let asset = assets.removeValue(forKey: id)!

        let estimatedMemory = estimatedMemory(of: asset)
        logger.trace("Removed \(id) saving \(estimatedMemory)")

        amountToGo = amountToGo - estimatedMemory
        currentMemoryUsage = currentMemoryUsage - estimatedMemory
      }
    }
  }
}

// swiftlint:enable shorthand_operator
