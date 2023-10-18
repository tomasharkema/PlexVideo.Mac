//
//  FileBasedCache.swift
//
//
//  Created by Tomas Harkema on 17/10/2023.
//

import Foundation
import UniformTypeIdentifiers
import OSLog

extension Logger {
  static let disabled = Logger(.disabled)
  static let `default` = Logger(.default)
}

protocol Cache {
  associatedtype Model: Identifiable

  func fetchByID(_ id: Model.ID) -> Model?
}

final class FileBasedCache: Cache, Sendable {
  var fileManager: FileManager
  let imageFormat: UTType
  let directory: URL
  var logger: Logger
  var signposter: OSSignposter

  init(
    directory: URL,
    imageFormat: UTType = .jpeg,
    logger: Logger = .default,
    fileManager: FileManager = .default
  ) {
    self.directory = directory
    self.logger = logger
    self.signposter = OSSignposter(logger: logger)
    self.imageFormat = imageFormat
    self.fileManager = fileManager
  }

  func createDirectoryIfNeeded() throws {
    try fileManager.createDirectory(
      at: self.directory,
      withIntermediateDirectories: true,
      attributes: nil
    )
  }

  func fetchByID(_ id: Asset.ID) -> Asset? {
    guard let image = PlexImage(contentsOfFile: self.url(forID: id).path) else {
      return nil
    }
    return Asset(id: id, image: image)
  }

  func addByMovingFromURL(_ url: URL, forAsset id: Asset.ID) {
    precondition(isMatchingImageType(url), "Asset at \(url) does not conform to \(imageFormat)")
    try? fileManager.moveItem(at: url, to: self.url(forID: id))
  }

  func clear() throws {
    try fileManager.removeItem(at: self.directory)
    try createDirectoryIfNeeded()
  }

  func isMatchingImageType(_ url: URL) -> Bool {
    return UTType(
      filenameExtension: url.pathExtension,
      conformingTo: imageFormat
    ) != nil
  }

  func url(forID id: Asset.ID) -> URL {
    return directory.appendingPathComponent(id).appendingPathExtension(for: imageFormat)
  }
}
