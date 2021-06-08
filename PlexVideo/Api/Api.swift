//
//  Api.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import CoreMedia
import Foundation
import UIKit

actor Api {
  static var shared = Api()
  private let jsonDecoder = JSONDecoder()

  private let root =
    URL(string: "https://192-168-1-102.e40e0158854249ae85a8d082f4a9ca9c.plex.direct:32400")!

  @MainActor
  private func _requestUrl(url: URL, token: String, queryItems: [URLQueryItem]? = nil) -> URL {
    var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!

    components.queryItems = components.queryItems ?? [] + [
      URLQueryItem(name: "X-Plex-Client-Identifier", value: Storage.uuid),
      URLQueryItem(name: "X-Plex-Client-Platform", value: "iOS"),
      URLQueryItem(name: "X-Plex-Device", value: "iPhone"),
      URLQueryItem(name: "X-Plex-Device-Screen-Density", value: "3"),
      URLQueryItem(name: "X-Plex-Device-Screen-Resolution", value: "1920x1080"),
      URLQueryItem(name: "X-Plex-Device-Vendor", value: "Apple"),
//      URLQueryItem(name: "X-Plex-Drm", value: "fairplay:video"),
//      URLQueryItem(name: "X-Plex-Http-Pipeline", value: "infinite"),
      URLQueryItem(name: "X-Plex-Model", value: "13,4"),
      URLQueryItem(name: "X-Plex-Platform", value: "iOS"),
      URLQueryItem(name: "X-Plex-Platform-Version", value: "14.6"),
      URLQueryItem(name: "X-Plex-Product", value: "Plex for iOS"),
//      URLQueryItem(
//        name: "X-Plex-Provides",
//        value: "client,controller,sync-target,player,pubsub-player,provider-playback"
//      ),
//      URLQueryItem(name: "X-Plex-Supported-Commands", value: "abort,changeQuality"),
      URLQueryItem(name: "X-Plex-Sync-Version", value: "2"),
      URLQueryItem(name: "X-Plex-Token", value: token),
      URLQueryItem(name: "X-Plex-Username", value: "teumaauss"),
      URLQueryItem(name: "X-Plex-Version", value: "7.19"),
      URLQueryItem(name: "X-Plex-Language", value: "nl"),
      URLQueryItem(name: "X-Plex-Device-Name", value: UIDevice().name),
      URLQueryItem(
        name: "X-Plex-Client-Profile-Extra",
        value: "add-limitation(scope=videoAudioCodec&scopeName=*&type=upperBound&name=audio.channels&value=6&replace=true)+add-transcode-target(type=musicProfile&context=streaming&protocol=hls&container=mpegts&audioCodec=aac)+add-direct-play-profile(type=musicProfile&container=mp4&audioCodec=alac)+add-direct-play-profile(type=musicProfile&container=flac&audioCodec=flac)+add-transcode-target(type=videoProfile&context=streaming&protocol=hls&container=mp4&videoCodec=h264,mpeg4,hevc,h265&audioCodec=aac,mp3,ac3,eac3,flac&id=hevcmp4)+add-transcode-target(type=videoProfile&context=streaming&protocol=hls&container=mpegts&videoCodec=h264,mpeg4,hevc,h265&audioCodec=aac,mp3,ac3,flac,eac3)+add-direct-play-profile(type=videoProfile&container=mp4,mov&videoCodec=h264,mpeg4,hevc,h265&audioCodec=aac,ac3,eac3,flac&subtitleCodec=mov_text,tx3g,ttxt,text)"
      ),
//      URLQueryItem(
//        name: "X-Plex-Client-Profile-Extra",
//        value: "add-limitation(scope=videoAudioCodec&scopeName=*&type=upperBound&name=audio.channels&value=6&replace=true)+add-transcode-target(type=musicProfile&context=streaming&protocol=hls&container=mpegts&audioCodec=aac)+add-direct-play-profile(type=musicProfile&container=mp4&audioCodec=alac)+add-direct-play-profile(type=musicProfile&container=flac&audioCodec=flac)+add-transcode-target(type=videoProfile&context=streaming&protocol=hls&container=mp4&videoCodec=h264,h265,hevc&audioCodec=aac,mp3,ac3,eac3&id=hevcmp4)+add-transcode-target(type=videoProfile&context=streaming&protocol=hls&container=mpegts&videoCodec=h264,h265,hevc&audioCodec=aac,mp3,ac3)+add-direct-play-profile(type=videoProfile&container=mp4,mov&videoCodec=h264,mpeg4,hevc,h265&audioCodec=aac,ac3,eac3&subtitleCodec=mov_text,tx3g,ttxt,text)"
//      ),

//      URLQueryItem(name: "X-Plex-Platform", value: "Chrome")

//      URLQueryItem(name: "X-Plex-Token", value: token),
//      URLQueryItem(name: "X-Plex-Version", value: "7.19"),
//      URLQueryItem(name: "X-Plex-Device", value: "iPad"),
//      URLQueryItem(name: "X-Plex-Model", value: "13,4"), // TODO: hardware version
//      URLQueryItem(name: "X-Plex-Device-Name", value: device.name),
//      URLQueryItem(name: "X-Plex-Device-Vendor", value: "Apple"),
//      URLQueryItem(name: "X-Plex-Http-Pipeline", value: "infinite"),
//      URLQueryItem(
//        name: "X-Plex-Platform",
//        value: "iOS"
//      ),
//      // TODO: have PMS to accept tvOS
//      URLQueryItem(name: "X-Plex-Client-Platform", value: "iOS"),
//      URLQueryItem(name: "X-Plex-Platform-Version", value: "14.6"),
//
//      URLQueryItem(
//        name: "X-Plex-Client-Identifier",
//        value: Storage.uuid.data(using: .utf8)!.base64EncodedString()
//      ),
//      URLQueryItem(
//        name: "X-Plex-Session-Identifier",
//        value: (Storage.uuid + "session").data(using: .utf8)!.base64EncodedString()
//      ),
//      URLQueryItem(name: "X-Plex-Device-Screen-Resolution", value: "2778x1284"),
//      URLQueryItem(name: "X-Plex-Product", value: "PlexVideo"), // TODO: actual App name
//      URLQueryItem(name: "X-Plex-Version", value: "0.1"), // TODO: version
//      URLQueryItem(name: "X-Plex-Language", value: "nl"),
    ] + (queryItems ?? [])

    let url = components.url!
    print("BUILT URL", url)
    return url
  }

  private func request<D: Decodable>(url: URL, token: String, method: String = "GET",
                                     queryItems: [URLQueryItem]? = nil) async throws -> D
  {
    var mutualRequest =
      URLRequest(url: await _requestUrl(url: url, token: token, queryItems: queryItems))
    mutualRequest.httpMethod = method
    mutualRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    let request = mutualRequest

    print("REQUEST:", request.url)

    let (data, r) = try await URLSession.shared.data(for: request, delegate: nil)

    print((r as? HTTPURLResponse)?.allHeaderFields["Content-Type"])

    let d = try JSONDecoder().decode(D.self, from: data)

    return d
  }

  func sections(token: String) async throws -> Root<DirectoryContainer> {
    return try await request(url: root.appendingPathComponent("/library/sections"), token: token)
  }

  func all(key: String, token: String) async throws -> Root<Metadata<Video>> {
    return try await request(
      url: root.appendingPathComponent("/library/sections/\(key)/all"),
      token: token
    )
  }

  func videos(token: String) async throws -> [Video] {
    let s = try await sections(token: token)
    let dirs = s.MediaContainer.Directory.filter {
      $0.type == "movie"
    }

    var videos = [Video]()

    for var dir in dirs {
      videos
        .append(contentsOf: try await self.all(key: dir.key, token: token).MediaContainer.Metadata)
    }

    return videos
  }

  private func status(token: String) async throws -> Root<Metadata<SessionStatus>> {
    return try await request(url: root.appendingPathComponent("/status/sessions"), token: token)
  }

  func videoUrl(video: Video, token: String, uuid: String,
                offset: Int) async throws -> URL
  {
    guard let media = video.Media?.first, let part = media.Part.first else {
      throw PlexError.noMedia
    }

    let isNativeFormat = ["hls"].contains(media.protocol) || ["mov", "mp4"]
      .contains(media.container) && ["mpeg4", "h264", "drmi", "hevc"]
      .contains(media.videoCodec) && ["aac", "ac3", "drms"].contains(media.audioCodec)

    let videoQueryItems = [
      URLQueryItem(name: "path", value: video.key),
      URLQueryItem(name: "partIndex", value: "0"),
      URLQueryItem(
        name: "session",
        value: uuid
      ),
      URLQueryItem(name: "protocol", value: "hls"),
      URLQueryItem(name: "directStream", value: "1"),
      URLQueryItem(name: "directPlay", value: "1"),
      URLQueryItem(name: "includeCodecs", value: "1"),
      URLQueryItem(name: "audioBoost", value: "100"),
      URLQueryItem(name: "autoAdjustQuality", value: "0"),
      URLQueryItem(name: "location", value: "lan"),
      URLQueryItem(name: "fastSeek", value: "1"),
      URLQueryItem(name: "directStreamAudio", value: "0"),
      URLQueryItem(name: "subtitles", value: "auto"),
      URLQueryItem(name: "mediaBufferSize", value: "40000"),
      URLQueryItem(name: "videoQuality", value: "100"),
      URLQueryItem(name: "offset", value: "\(offset)"),
      URLQueryItem(name: "addDebugOverlay", value: "0"),
//      URLQueryItem(name: "videoResolution", value: "1920x1080"),
    ]

    let des: Root<Metadata<Video>> = try await request(
      url: root.appendingPathComponent("/video/:/transcode/universal/decision"),
      token: token,
      queryItems:
      videoQueryItems
    )
    print(des)
    return await self._requestUrl(
      url: self.root.appendingPathComponent("/video/:/transcode/universal/start.m3u8"),
      token: token,
      queryItems:
      videoQueryItems
    )
  }

  func imageUrl(item: Video, token: String, width: Int, height: Int) async -> URL {
    return await self._requestUrl(
      url: root.appendingPathComponent("/photo/:/transcode"),
      token: token,
      queryItems: [
        URLQueryItem(name: "url", value: item.thumb),
        URLQueryItem(name: "width", value: "\(width)"),
        URLQueryItem(name: "height", value: "\(height)"),
        URLQueryItem(name: "upscale", value: "1"),
      ]
    )
  }

  func timeline(video: Video, time: CMTime, state: PlayingState,
                token: String) async -> Result<Root<TranscodeSession>, Error>
  {
    do {
      return .success(try await request(
        url: root.appendingPathComponent("/:/timeline"),
        token: token,
        queryItems: [
          URLQueryItem(name: "time", value: "\(Int(time.seconds * 1000))"),
          URLQueryItem(name: "ratingKey", value: video.ratingKey),
          URLQueryItem(name: "duration", value: "\(Int(video.Media?.first?.duration.value ?? 0))"),
          URLQueryItem(name: "state", value: state.rawValue),
          URLQueryItem(name: "key", value: video.key),
          URLQueryItem(name: "context", value: "library%3Acontent.library"),
        ]
      ))

    } catch {
      print(error)
      return .failure(error)
    }
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
