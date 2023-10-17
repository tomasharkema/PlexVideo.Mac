//
//  Api.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import CoreMedia
import Foundation
//import UIKit
// import XMLCoder
import AsyncAwaitHelpers

struct VideoSessionUUID: RawRepresentable {
  let rawValue: String
}

@MainActor
struct DeviceInfo {
  @MainActor
  static let shared = DeviceInfo()

  let platform = "tvOS" // UIDevice().systemName
  // let platform = "Windows"
  let name = UIDevice().name
  let device = "iPhone"
  let version = "14.6"
  let appVersion = "0.1"
  let product = "PlexVideo"
}

@MainActor
class ImageCache {
  static let shared = ImageCache()
  var thumbCache: [VideoKey: URL] = [:]
}

class Api {
  static let shared = Api()
  private let serverLocator = ServerLocator.locator
  private let requestor = Requestor.shared

  func sections() async throws -> Root<DirectoryContainer> {
    try await requestor.request(
      url: serverLocator.root()
        .appendingPathComponent("/library/sections")
    )
  }

  func all(key: SectionKey) async throws -> Root<Metadata<Video>> {
    try await requestor.request(
      url: serverLocator.root()
        .appendingPathComponent("/library/sections/\(key.rawValue)/all")
    )
  }

  func onDeck(ratingKey: RatingKey) async throws -> Root<Metadata<Video>> {
    try await requestor.request(
      url: serverLocator.root()
        .appendingPathComponent("/library/metadata/\(ratingKey.rawValue)"),
      queryItems: [URLQueryItem(name: "includeOnDeck", value: "1")]
    )
  }

  private func status() async throws -> Root<Metadata<SessionStatus>> {
    try await requestor.request(
      url: serverLocator.root()
        .appendingPathComponent("/status/sessions")
    )
  }

  func videoQueryItems(videoKey: VideoKey, videoUuid: VideoSessionUUID, offset: Int,
                       vr: String? = "4096x2160") -> [URLQueryItem]
  {
    [
      URLQueryItem(name: "videoResolution", value: vr),
      URLQueryItem(name: "path", value: videoKey.rawValue),
      URLQueryItem(name: "partIndex", value: "0"),
      URLQueryItem(
        name: "session",
        value: videoUuid.rawValue
      ),
      URLQueryItem(name: "protocol", value: "hls"),
      URLQueryItem(name: "directStream", value: "1"),
      URLQueryItem(name: "directPlay", value: "1"),
      URLQueryItem(name: "includeCodecs", value: "1"),
      URLQueryItem(name: "audioBoost", value: "100"),
      URLQueryItem(name: "autoAdjustQuality", value: "1"),
      URLQueryItem(name: "location", value: "lan"),
      URLQueryItem(name: "fastSeek", value: "1"),
      URLQueryItem(name: "directStreamAudio", value: "1"),
      URLQueryItem(name: "subtitles", value: "auto"),
      URLQueryItem(name: "mediaBufferSize", value: "40000"),
      URLQueryItem(name: "videoQuality", value: "100"),
      URLQueryItem(name: "offset", value: "\(offset)"),
      URLQueryItem(name: "addDebugOverlay", value: "0"),
    ]
  }

  func decision(
    videoKey: VideoKey,
    videoUuid: VideoSessionUUID,
    offset: Int,
    videoResolution: String? = "4096x2160"
  ) async throws -> Root<Metadata<Video>> {
    try await requestor.request(
      url: serverLocator.root()
        .appendingPathComponent("/video/:/transcode/universal/decision"),
      queryItems: videoQueryItems(
        videoKey: videoKey,
        videoUuid: videoUuid,
        offset: offset,
        vr: videoResolution
      )
    )
  }

  func videoUrl(video: Video, videoUuid: VideoSessionUUID, offset: Int) async throws -> URL {
//    guard let media = videob

//    let isNativeFormat = ["hls"].contains(media.protocol) || ["mov", "mp4"]
//      .contains(media.container) && ["mpeg4", "h264", "drmi", "hevc"]
//      .contains(media.videoCodec) && ["aac", "ac3", "drms"].contains(media.audioCodec)

//    let resu = try await decision(
//      videoKey: video.key,
//      videoUuid: videoUuid,
//      offset: offset
//    )
//
//    print(resu)

    try await requestor._requestUrl(
      url: serverLocator.root()
        .appendingPathComponent("/video/:/transcode/universal/start.m3u8"),
      queryItems:
      videoQueryItems(
        videoKey: video.key,
        videoUuid: videoUuid,
        offset: offset
      )
    )
  }

  func imageUrl(item: Video, width: Int, height: Int) async throws
    -> URL
  {
    let url = try await requestor._requestUrl(
      url: serverLocator.root()
        .appendingPathComponent("/photo/:/transcode"),
      queryItems: [
        URLQueryItem(name: "url", value: item.grandparentThumb ?? item.thumb),
        URLQueryItem(name: "width", value: "\(width)"),
        URLQueryItem(name: "height", value: "\(height)"),
        URLQueryItem(name: "upscale", value: "1"),
      ]
    )

    Task { @MainActor in
      ImageCache.shared.thumbCache[item.key] = url
    }
    return url
  }

  func timeline(video: Video, time: CMTime,
                state: PlayingState) async throws -> Root<TranscodeSessions>
  {
    return try await requestor.request(
        url: serverLocator.root()
          .appendingPathComponent("/:/timeline"),
        queryItems: [
          URLQueryItem(name: "time", value: "\(Int(time.seconds * 1000))"),
          URLQueryItem(name: "ratingKey", value: video.ratingKey.rawValue),
          URLQueryItem(
            name: "duration",
            value: "\(Int(video.Media?.first?.duration.value ?? 0))"
          ),
          URLQueryItem(name: "state", value: state.rawValue),
          URLQueryItem(name: "key", value: video.key.rawValue),
          URLQueryItem(name: "context", value: "library%3Acontent.library"),
        ]
      )
  }

  func continueWatching(contentDirectoryIDs: [SectionKey]) async throws -> Root<Hub<Video>> {
    try await requestor.request(
      url: serverLocator.root().appendingPathComponent("/hubs/continueWatching"),
      queryItems: [
        URLQueryItem(
          name: "contentDirectoryID",
          value: contentDirectoryIDs.map(\.rawValue).joined(separator: ",")
        ),
        URLQueryItem(name: "includeMeta", value: "1"),
      ]
    )
  }
}

enum PlayingState: String {
  case playing
  case paused
  case stopped
}

enum PlexError: Error {
  case noMedia
}
