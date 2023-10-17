//
//  Api.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import CoreMedia
import Foundation
import Inject
import PlexShared

public final class Api {

  @Injected(\.serverLocator)
  private var serverLocator

  @Injected(\.requestor)
  private var requestor

//  @Injected(\.imageCache)
//  private var imageCache

  public func sections(deviceInfo: DeviceInfo) async throws -> Root<DirectoryContainer> {
    try await requestor.request(
      url: serverLocator.root(deviceInfo: deviceInfo)
        .appendingPathComponent("/library/sections"),
      deviceInfo: deviceInfo
    )
  }

  public func all(key: SectionKey, deviceInfo: DeviceInfo) async throws -> Root<Metadata<Video>> {
    try await requestor.request(
      url: serverLocator.root(deviceInfo: deviceInfo)
        .appendingPathComponent("/library/sections/\(key.rawValue)/all"),
      deviceInfo: deviceInfo
    )
  }

  public func onDeck(ratingKey: RatingKey, deviceInfo: DeviceInfo) async throws -> Root<Metadata<Video>> {
    try await requestor.request(
      url: serverLocator.root(deviceInfo: deviceInfo)
        .appendingPathComponent("/library/metadata/\(ratingKey.rawValue)"),
      deviceInfo: deviceInfo,
      queryItems: [URLQueryItem(name: "includeOnDeck", value: "1")]
    )
  }

  private func status(deviceInfo: DeviceInfo) async throws -> Root<Metadata<SessionStatus>> {
    try await requestor.request(
      url: serverLocator.root(deviceInfo: deviceInfo)
        .appendingPathComponent("/status/sessions"),
      deviceInfo: deviceInfo
    )
  }

  func videoQueryItems(
    videoKey: VideoKey,
    videoUuid: VideoSessionUUID,
    offset: Int,
    videoResolution: String? = "4096x2160",
    subtitles: String?
  ) -> [URLQueryItem] {
    [
      URLQueryItem(name: "videoResolution", value: videoResolution),
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
      URLQueryItem(name: "subtitles", value: subtitles ?? ""),
      URLQueryItem(name: "mediaBufferSize", value: "40000"),
      URLQueryItem(name: "videoQuality", value: "100"),
      URLQueryItem(name: "offset", value: "\(offset)"),
      URLQueryItem(name: "addDebugOverlay", value: "0"),
    ]
  }

//  func decision(
//    videoKey: VideoKey,
//    videoUuid: VideoSessionUUID,
//    offset: Int,
//    videoResolution: String? = "4096x2160",
//    subtitles: String?,
//    deviceInfo: DeviceInfo
//  ) async throws -> Root<Metadata<Video>> {
//    try await requestor.request(
//      url: serverLocator.root(deviceInfo: deviceInfo)
//        .appendingPathComponent("/video/:/transcode/universal/decision"),
//      deviceInfo: deviceInfo,
//      queryItems: videoQueryItems(
//        videoKey: videoKey,
//        videoUuid: videoUuid,
//        offset: offset,
//        vr: videoResolution,
//        subtitles: subtitles
//      )
//    )
//  }

  public func videoUrl(
    video: Video, videoUuid: VideoSessionUUID, offset: Int, deviceInfo: DeviceInfo
  ) async throws -> URL {
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

    try await requestor.requestUrl(
      url: serverLocator.root(deviceInfo: deviceInfo)
        .appendingPathComponent("/video/:/transcode/universal/start.m3u8"),
      deviceInfo: deviceInfo,
      queryItems:
      videoQueryItems(
        videoKey: video.key,
        videoUuid: videoUuid,
        offset: offset,
        subtitles: "auto"
      )
    )
  }

  public func imageUrl(
    root: URL,
    item: Video,
    width: Int,
    height: Int,
    deviceInfo: DeviceInfo,
    uuid: String?,
    token: String?
  ) -> URL {

    let url = requestor.requestUrl(
      url: root.appendingPathComponent("/photo/:/transcode"),
      deviceInfo: deviceInfo,
      queryItems: [
        URLQueryItem(name: "url", value: item.grandparentThumb ?? item.thumb),
        URLQueryItem(name: "width", value: "\(width)"),
        URLQueryItem(name: "height", value: "\(height)"),
//        URLQueryItem(name: "upscale", value: "1"),
      ],
      uuid: uuid,
      token: token
    )

//    Task(priority: .background) { @MainActor in
//      self.imageCache.thumbCache[item.key] = url
//    }
    
    return url
  }

  public func timeline(
    video: Video, time: CMTime,
    state: PlayingState, deviceInfo: DeviceInfo
  ) async throws -> Root<TranscodeSessions> {
    return try await requestor.request(
      url: serverLocator.root(deviceInfo: deviceInfo)
          .appendingPathComponent("/:/timeline"),
        deviceInfo: deviceInfo,
        queryItems: [
          URLQueryItem(name: "time", value: "\(Int(time.seconds * 1000))"),
          URLQueryItem(name: "ratingKey", value: video.ratingKey.rawValue),
          URLQueryItem(
            name: "duration",
            value: "\(Int(video.media?.first?.duration.value ?? 0))"
          ),
          URLQueryItem(name: "state", value: state.rawValue),
          URLQueryItem(name: "key", value: video.key.rawValue),
          URLQueryItem(name: "context", value: "library%3Acontent.library"),
        ]
      )
  }

  public func continueWatching(contentDirectoryIDs: [SectionKey], deviceInfo: DeviceInfo) async throws -> Root<Hub<Video>> {
    try await requestor.request(
      url: serverLocator.root(deviceInfo: deviceInfo).appendingPathComponent("/hubs/continueWatching"),
      deviceInfo: deviceInfo,
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

public enum PlayingState: String {
  case playing
  case paused
  case stopped
}

enum PlexError: Error {
  case noMedia
}

public extension InjectedValues {
  var api: Api {
    get { Self[ApiKey.self] }
    set { Self[ApiKey.self] = newValue }
  }
}

private struct ApiKey: InjectionKey {
  static var currentValue: Api = .init()
}
