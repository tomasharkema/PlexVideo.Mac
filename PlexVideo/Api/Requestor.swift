//
//  Requestor.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 09/06/2021.
//

import Foundation
// import XMLCoder

class Requestor {
  static let shared = Requestor()

  func _requestUrl(
    url: URL,
    queryItems: [URLQueryItem]? = nil,
    sendDefaultQueries: Bool = true
  ) async -> URL {
    async let uuid = Storage.shared.getUUID()
    async let token = Storage.shared.getToken()

    var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
    components.queryItems = await (components.queryItems ?? []) + (sendDefaultQueries ? [
      URLQueryItem(name: "X-Plex-Client-Identifier", value: uuid),
      URLQueryItem(name: "X-Plex-Client-Platform", value: DeviceInfo.shared.platform),
      URLQueryItem(name: "X-Plex-Device", value: DeviceInfo.shared.device),
      URLQueryItem(name: "X-Plex-Device-Screen-Density", value: "3"),
      URLQueryItem(name: "X-Plex-Device-Screen-Resolution", value: "1920x1080"),
      URLQueryItem(name: "X-Plex-Device-Vendor", value: "Apple"),
      URLQueryItem(name: "X-Plex-Model", value: "13,4"),
      URLQueryItem(name: "X-Plex-Platform", value: DeviceInfo.shared.platform),
      URLQueryItem(name: "X-Plex-Platform-Version", value: DeviceInfo.shared.version),
      URLQueryItem(name: "X-Plex-Product", value: DeviceInfo.shared.product),
      URLQueryItem(name: "X-Plex-Sync-Version", value: "2"),
      URLQueryItem(name: "X-Plex-Token", value: token),
      URLQueryItem(name: "X-Plex-Username", value: "teumaauss"),
      URLQueryItem(name: "X-Plex-Version", value: DeviceInfo.shared.appVersion),
      URLQueryItem(name: "X-Plex-Language", value: "nl"),
      URLQueryItem(name: "X-Plex-Device-Name", value: DeviceInfo.shared.name),
//      URLQueryItem(
//        name: "X-Plex-Client-Profile-Extra",
//        value: "add-limitation(scope=videoAudioCodec&scopeName=*&type=upperBound&name=audio.channels&value=8&replace=true)+add-transcode-target(type=musicProfile&context=streaming&protocol=hls&container=mpegts&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3)+add-direct-play-profile(type=musicProfile&container=mp4&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3)+add-direct-play-profile(type=musicProfile&container=flac&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3)+add-transcode-target(type=videoProfile&context=streaming&protocol=hls&container=mp4&videoCodec=hevc&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3&id=hevcmp4)+add-transcode-target(type=videoProfile&context=streaming&protocol=hls&container=mpegts&videoCodec=h264&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3)+add-direct-play-profile(type=videoProfile&container=mp4,mov&videoCodec=h264,mpeg4&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3&subtitleCodec=mov_text,tx3g,ttxt,text)"
//      ),
    ] : []) + (queryItems ?? [])

    let url = components.url!
    print("BUILT URL", url)
    return url
  }

  func request<D: Decodable>(
    url: URL,
    method: String = "GET",
    queryItems: [URLQueryItem]? = nil,
    sendDefaultQueries: Bool = true,
    timeoutInterval: TimeInterval? = nil,
    invalidateAfterError: Bool = true
  ) async throws -> D {
    var mutualRequest =
      await URLRequest(url: _requestUrl(
        url: url,
        queryItems: queryItems,
        sendDefaultQueries: sendDefaultQueries
      ))
    mutualRequest.httpMethod = method
    mutualRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    if let timeoutInterval {
      mutualRequest.timeoutInterval = timeoutInterval
    }
    let request = mutualRequest
    do {
      async let (data, _) = URLSession.shared.data(for: request, delegate: nil)

//      if (((r as? HTTPURLResponse)?.allHeaderFields["Content-Type"]) as? String)?
//        .contains("xml") == true
//      {
//        do {
//          return try XMLDecoder().decode(D.self, from: data)
//        } catch {
//          print(error)
//          print(error)
//        }
//      }
      do {
        return try await JSONDecoder().decode(D.self, from: data)
      } catch {
        let json = try? await String(data: data, encoding: .utf8)!
        print(error, request.url!, json)
        throw error
      }
    } catch let error as URLError {
      print(error)
      print(error.code)

      if invalidateAfterError,
         error.code == .cannotConnectToHost || error.code == .cannotFindHost || error
         .code == .dnsLookupFailed
      {
        print("HOST NOT FOUND!")
        Task {
          await ServerLocator.locator.invalidate()
        }
      }
//
      throw error
    } catch {
      print(error, url)
      throw error
    }
  }
}
