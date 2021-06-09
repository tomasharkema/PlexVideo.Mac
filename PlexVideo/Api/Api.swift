//
//  Api.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import CoreMedia
import Foundation
import UIKit
//import XMLCoder

let platform = UIDevice().systemName
// let platform = "Windows"
let name = UIDevice().name
let device = "iPhone"
let version = "14.6"
let appVersion = "0.1"
let product = "PlexVideo"

actor Api {
  static var shared = Api()
  private let jsonDecoder = JSONDecoder()

  @MainActor
  private func _requestUrl(
    url: URL,
    token: String?,
    queryItems: [URLQueryItem]? = nil,
    sendDefaultQueries: Bool = true
  ) -> URL {
    var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!

    components.queryItems = (components.queryItems ?? []) + (sendDefaultQueries ? [
      URLQueryItem(name: "X-Plex-Client-Identifier", value: Storage.shared.uuid),
      URLQueryItem(name: "X-Plex-Client-Platform", value: platform),
      URLQueryItem(name: "X-Plex-Device", value: device),
      URLQueryItem(name: "X-Plex-Device-Screen-Density", value: "3"),
      URLQueryItem(name: "X-Plex-Device-Screen-Resolution", value: "1920x1080"),
      URLQueryItem(name: "X-Plex-Device-Vendor", value: "Apple"),
//      URLQueryItem(name: "X-Plex-Drm", value: "fairplay:video"),
//      URLQueryItem(name: "X-Plex-Http-Pipeline", value: "infinite"),
      URLQueryItem(name: "X-Plex-Model", value: "13,4"),
      URLQueryItem(name: "X-Plex-Platform", value: platform),
      URLQueryItem(name: "X-Plex-Platform-Version", value: version),
      URLQueryItem(name: "X-Plex-Product", value: product),
//      URLQueryItem(
//        name: "X-Plex-Provides",
//        value: "client,controller,sync-target,player,pubsub-player,provider-playback"
//      ),
//      URLQueryItem(name: "X-Plex-Supported-Commands", value: "abort,changeQuality"),
      URLQueryItem(name: "X-Plex-Sync-Version", value: "2"),
      URLQueryItem(name: "X-Plex-Token", value: token),
      URLQueryItem(name: "X-Plex-Username", value: "teumaauss"),
      URLQueryItem(name: "X-Plex-Version", value: appVersion),
      URLQueryItem(name: "X-Plex-Language", value: "nl"),
      URLQueryItem(name: "X-Plex-Device-Name", value: name),
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
    ] : []) + (queryItems ?? [])

    let url = components.url!
    print("BUILT URL", url)
    return url
  }

  private func request<D: Decodable>(
    url: URL,
    token: String?,
    method: String = "GET",
    queryItems: [URLQueryItem]? = nil,
    sendDefaultQueries: Bool = true,
    timeoutInterval: TimeInterval? = nil
  ) async throws -> D {
    var mutualRequest =
      URLRequest(url: await _requestUrl(
        url: url,
        token: token,
        queryItems: queryItems,
        sendDefaultQueries: sendDefaultQueries
      ))
    mutualRequest.httpMethod = method
    mutualRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    mutualRequest.timeoutInterval = timeoutInterval ?? 30
    let request = mutualRequest

    let (data, r) = try await URLSession.shared.data(for: request, delegate: nil)
//
//    if (((r as? HTTPURLResponse)?.allHeaderFields["Content-Type"]) as? String)?.contains("application/xml") == true {
//      do {
//        return try XMLDecoder().decode(D.self, from: data)
//      }
//      catch {
//        print(error)
//        print(error)
//      }
//    }

    return try JSONDecoder().decode(D.self, from: data)
  }

  private var lastUsedRoot: URL?

  private func ping(server: URL) async throws -> Root<Version> {
    return try await self.request(url: server, token: token, timeoutInterval: 5)
  }

  func root(force: Bool = false) async throws -> URL {
    if let lastUsedRoot = lastUsedRoot, !force {
      return lastUsedRoot
    }

    if let storage = Storage.shared.lastUsedHost {
      do {
        let _ = try await ping(server: storage)
        return storage
      } catch {
        print(error)
      }
    }

    let d = try await devices()
    print(d)

    let servers = d.filter {
      $0.provides.contains("server")
    }.flatMap { server in
      server.connections.filter { $0.protocol == "https" }
    }.sorted { (l, r) in
      return (l.local ? 100 : 0) > (r.local ? 100 : 0)
    }.flatMap {
      URL(string: $0.uri).map { [$0] } ?? []
    }

    guard let token = Storage.shared.plexToken else  {
      throw NSError(domain: "DERP", code: 0, userInfo: nil)
    }

    let pings = await withTaskGroup(of: [(URL, Double, Int)].self) { group in
      for (index, server) in servers.enumerated() {
        if Task.isCancelled { break }
        group.async {
          let date = Date()
          do {
            let _: Root<Version> = try await self.request(url: server, token: token, timeoutInterval: 5)
            // CANCEL ALL OTHERS!
            return [(server, Date().timeIntervalSince(date), index + 1)]
          } catch {
            print(error)
            return []
          }
        }
      }

      return await group.reduce([], +)
    }

    guard let url = pings.sorted { $0.1 * Double($0.2) < $1.1 * Double($0.2) }.first?.0 else {
      throw NSError(domain: "", code: 0, userInfo: nil)
    }

    lastUsedRoot = url
    Storage.shared.lastUsedHost = url

    return url
  }

  func devices() async throws -> [Device] {
    return try await request(url: URL(string: "https://plex.tv/api/v2/resources?")!, token: Storage.shared.plexToken, queryItems: [URLQueryItem(name: "includeHttps", value: "1"),URLQueryItem(name: "includeRelay", value: "1")])
  }

  func sections(token: String) async throws -> Root<DirectoryContainer> {
    return try await request(url: (try await root()).appendingPathComponent("/library/sections"), token: token)
  }

  func all(key: String, token: String) async throws -> Root<Metadata<Video>> {
    return try await request(
      url: (try await root()).appendingPathComponent("/library/sections/\(key)/all"),
      token: token
    )
  }

  func videos(token: String) async throws -> [Video] {
    let s = try await sections(token: token)
    let dirs = s.MediaContainer.Directory.filter {
      $0.type == "movie"
    }

    let videos: [Video] = try await withThrowingTaskGroup(of: [Video].self, body: { group in
      for dir in dirs {
        group.async {
          (try await self.all(key: dir.key, token: token)).MediaContainer.Metadata
        }
      }
      return try await group.reduce([], +)
    })

    return videos
  }

  private func status(token: String) async throws -> Root<Metadata<SessionStatus>> {
    return try await request(url: (try await root()).appendingPathComponent("/status/sessions"), token: token)
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
      url: (try await root()).appendingPathComponent("/video/:/transcode/universal/decision"),
      token: token,
      queryItems:
      videoQueryItems
    )
    print(des)
    return await self._requestUrl(
      url: (try await self.root()).appendingPathComponent("/video/:/transcode/universal/start.m3u8"),
      token: token,
      queryItems:
      videoQueryItems
    )
  }

  func imageUrl(item: Video, token: String, width: Int, height: Int) async throws -> URL {
    return await self._requestUrl(
      url: (try await self.root()).appendingPathComponent("/photo/:/transcode"),
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
        url: (try await root()).appendingPathComponent("/:/timeline"),
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

  func pollForPin(pinId: Int, requestDelay: Double, maxRetries: Int) async throws -> String {
    try Task.checkCancellation()

    if maxRetries <= 0 {
      throw NSError(domain: "LIMIT REACHED", code: 0, userInfo: nil)
    }

    Thread.sleep(forTimeInterval: requestDelay)

    do {
      let token: PinToken = try await request(
        url: URL(
          string: "https://plex.tv/api/v2/pins/\(pinId)?X-Plex-Client-Identifier=\(await Storage.shared.uuid)&X-Plex-Product=\(product)&X-Plex-Platform=\(platform)&X-Plex-Platform-Version=\(version)&X-Plex-Device-Name=\(product)&X-Plex-Version=\(appVersion)"
        )!,
        token: nil,
        sendDefaultQueries: false
      )

      if let authToken = token.authToken {
        Storage.shared.plexToken = authToken
        return authToken
      } else {
        return try await pollForPin(
          pinId: pinId,
          requestDelay: min(20, requestDelay + 0.5),
          maxRetries: maxRetries - 1
        )
      }
    } catch {
      print("ERROR", error)
      return try await pollForPin(
        pinId: pinId,
        requestDelay: min(20, requestDelay + 0.5),
        maxRetries: maxRetries - 1
      )
    }
  }

  func authUrl() async throws -> (URL, Int) {
    let data: PinToken = try await request(
      url: URL(
        string: "https://plex.tv/api/v2/pins?X-Plex-Client-Identifier=\(await Storage.shared.uuid)&X-Plex-Product=\(product)&X-Plex-Platform=\(platform)&X-Plex-Platform-Version=7&X-Plex-Device-Name=\(product)&X-Plex-Version=3.2.2.5080&strong=True"
      )!,
      token: nil,
      method: "POST",
      sendDefaultQueries: false
    )

    let url =
      "https://app.plex.tv/auth/#!?clientID=\(data.clientIdentifier)&code=\(data.code)&context[device][product]=\(product)&context[device][platform]=\(platform)&context[device][platformVersion]=7&context[device][version]=3.2.2.5080"

    guard let url = URL(
      string: url
    ) else {
      throw NSError(domain: "NO URL", code: 0, userInfo: nil)
    }
    print(url)
    return (url, Int(data.id.value))
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
