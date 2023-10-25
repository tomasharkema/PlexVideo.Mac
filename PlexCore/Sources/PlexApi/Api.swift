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

public final class Api: Sendable {
  //  @Injected(\.serverLocator)
  //  private var serverLocator

  @Injected(\.requestor)
  private var requestor

  public func sections(
    server: ServerWithCurrentConnection,
                       onlyCached: Bool
  ) async throws -> Root<DirectoryContainer> {
    try await requestor.request(
      url: server.uri
        .appendingPathComponent("/library/sections"),
      Root<DirectoryContainer>.self,
      onlyCached: onlyCached
    )
  }

  public func all(
    server: ServerWithCurrentConnection,
    key: SectionKey,
    reload: Bool,
    onlyCached: Bool
  ) async throws
    -> Root<Metadata<Video>>
  {
    try await requestor.request(
      url: server.uri
        .appendingPathComponent("/library/sections/\(key.rawValue)/all"),
      Root<Metadata<Video>>.self,
      useCache: !reload,
      onlyCached: onlyCached
    )
  }

  public func onDeck(
    server: ServerWithCurrentConnection, ratingKey: RatingKey
  ) async throws
    -> Root<Metadata<Video>>
  {
    try await requestor.request(
      url: server.uri
        .appendingPathComponent("/library/metadata/\(ratingKey.rawValue)"),
      Root<Metadata<Video>>.self,
      queryItems: [URLQueryItem(name: "includeOnDeck", value: "1")]
    )
  }

  public func sessions(
    server: ServerWithCurrentConnection
  ) async throws -> Root<
    Metadata<SessionStatus>
  > {
    try await requestor.request(
      url: server.uri
        .appendingPathComponent("/status/sessions"),
      Root<Metadata<SessionStatus>>.self
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
  //      url: serverLocator.root()
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
    server: ServerWithCurrentConnection,
    video: Video,
    videoUuid: VideoSessionUUID,
    offset: Int
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
      url: server.uri
        .appendingPathComponent("/video/:/transcode/universal/start.m3u8"),
      queryItems:
      videoQueryItems(
        videoKey: video.key,
        videoUuid: videoUuid,
        offset: offset,
        subtitles: "auto"
      )
    )
  }

  @MainActor
  public func imageUrl(
    item: VideoFromServer,
    width: Int,
    height: Int,
    uuid: String?,
    token: String?
  ) -> URL {
    requestor.requestUrl(
      url: item.server.connection.uri.appendingPathComponent("/photo/:/transcode"),
      queryItems: [
        URLQueryItem(name: "url", value: item.video.grandparentThumb ?? item.video.thumb),
        URLQueryItem(name: "width", value: "\(width)"),
        URLQueryItem(name: "height", value: "\(height)"),
        URLQueryItem(name: "upscale", value: "1"),
      ],
      uuid: uuid,
      token: token
    )
  }

  public func timeline(
    server: ServerWithCurrentConnection,
    video: Video,
    time: CMTime,
    state: PlayingState
  ) async throws -> Root<TranscodeSessions> {
    try await requestor.request(
      url: server.uri
        .appendingPathComponent("/:/timeline"),
      Root<TranscodeSessions>.self,
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

  public func continueWatching(
    server: ServerWithCurrentConnection,
    contentDirectoryIDs: [SectionKey]
  ) async throws -> Root<Hub<Video>> {
    try await requestor.request(
      url: server.uri.appendingPathComponent("/hubs/continueWatching"),
      Root<Hub<Video>>.self,
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

enum PlexError: Error {
  case noMedia
}

public extension DateFormatter {
  static let iso8601Full: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    //    formatter.calendar = Calendar(identifier: .iso8601)
    //    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    //    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()
}

public extension JSONDecoder {
  static let `default`: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(.iso8601Full)
    return decoder
  }()
}

public extension InjectedValues {
  var api: Api {
    get { Self[ApiKey.self] }
    set { Self[ApiKey.self] = newValue }
  }
}

private struct ApiKey: InjectionKey {
  static var currentValue: Api? = .init()
}
