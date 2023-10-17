//
//  Requestor.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 09/06/2021.
//

import Foundation
// import XMLCoder
import Inject
import OSLog

public final class Requestor {

  private let logger = Logger(subsystem: "PlexVideo", category: "Requestor")

  @Injected(\.serverLocator)
  private var serverLocator

  @Injected(\.storage)
  private var storage

  func _requestUrl(
    url: URL,
    deviceInfo: DeviceInfo,
    queryItems: [URLQueryItem]? = nil,
    sendDefaultQueries: Bool = true
  ) async -> URL {
    let token = await storage.getToken()
    let uuid = await storage.uuid

    return _requestUrl(
      url: url, deviceInfo: deviceInfo, 
      queryItems: queryItems,
      sendDefaultQueries: sendDefaultQueries,
      uuid: uuid,
      token: token
    )
  }

  func _requestUrl(
    url: URL,
    deviceInfo: DeviceInfo,
    queryItems: [URLQueryItem]? = nil,
    sendDefaultQueries: Bool = true,
    uuid: String?,
    token: String?
  ) -> URL {

    var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
    components.queryItems = (components.queryItems ?? []) + (sendDefaultQueries ? [
      URLQueryItem(name: "X-Plex-Client-Identifier", value: uuid),
      URLQueryItem(name: "X-Plex-Client-Platform", value: deviceInfo.platform),
      URLQueryItem(name: "X-Plex-Device", value: deviceInfo.device),
      URLQueryItem(name: "X-Plex-Device-Screen-Density", value: "3"),
      URLQueryItem(name: "X-Plex-Device-Screen-Resolution", value: "1920x1080"),
      URLQueryItem(name: "X-Plex-Device-Vendor", value: "Apple"),
      URLQueryItem(name: "X-Plex-Model", value: "13,4"),
      URLQueryItem(name: "X-Plex-Platform", value: deviceInfo.platform),
      URLQueryItem(name: "X-Plex-Platform-Version", value: deviceInfo.version),
      URLQueryItem(name: "X-Plex-Product", value: deviceInfo.product),
      URLQueryItem(name: "X-Plex-Sync-Version", value: "2"),
      URLQueryItem(name: "X-Plex-Token", value: token),
      URLQueryItem(name: "X-Plex-Username", value: "teumaauss"),
      URLQueryItem(name: "X-Plex-Version", value: deviceInfo.appVersion),
      URLQueryItem(name: "X-Plex-Language", value: "nl"),
      URLQueryItem(name: "X-Plex-Device-Name", value: deviceInfo.name),
//      URLQueryItem(
//        name: "X-Plex-Client-Profile-Extra",
//        value: "add-limitation(scope=videoAudioCodec&scopeName=*&type=upperBound&name=audio.channels&value=8&replace=true)+add-transcode-target(type=musicProfile&context=streaming&protocol=hls&container=mpegts&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3)+add-direct-play-profile(type=musicProfile&container=mp4&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3)+add-direct-play-profile(type=musicProfile&container=flac&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3)+add-transcode-target(type=videoProfile&context=streaming&protocol=hls&container=mp4&videoCodec=hevc&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3&id=hevcmp4)+add-transcode-target(type=videoProfile&context=streaming&protocol=hls&container=mpegts&videoCodec=h264&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3)+add-direct-play-profile(type=videoProfile&container=mp4,mov&videoCodec=h264,mpeg4&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3&subtitleCodec=mov_text,tx3g,ttxt,text)"
//      ),
    ] : []) + (queryItems ?? [])

    let url = components.url!
    
//#if DEBUG
//    logger.info("BUILT URL \(url)")
//#endif

    return url
  }

  nonisolated func request<DecodableType: Decodable>(
    url: URL,
    deviceInfo: DeviceInfo,
    method: String = "GET",
    queryItems: [URLQueryItem]? = nil,
    sendDefaultQueries: Bool = true,
    timeoutInterval: TimeInterval? = nil,
    invalidateAfterError: Bool = true,
    useCache: Bool = true
  ) async throws -> DecodableType {

    var mutualRequest =
      URLRequest(
        url: await _requestUrl(
          url: url,
          deviceInfo: deviceInfo,
          queryItems: queryItems,
          sendDefaultQueries: sendDefaultQueries
        ),
        cachePolicy: useCache ? .returnCacheDataElseLoad : .reloadIgnoringLocalAndRemoteCacheData
      )

    mutualRequest.httpMethod = method
    mutualRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    if let timeoutInterval = timeoutInterval {
      mutualRequest.timeoutInterval = timeoutInterval
    }
//    let request = mutualRequest
    do {
      let session = URLSession.shared
      let (data, _) = try await session.data(for: mutualRequest, delegate: nil)

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
        return try JSONDecoder().decode(DecodableType.self, from: data)
      } catch {
        #if DEBUG
        logger.error("JSON ERROR: \(error) \(url) \(String(data: data, encoding: .utf8) ?? "")")
        #endif
        throw error
      }
    } catch let error as URLError {
      logger.error("request URLError \(error), \(String(describing: error.code)), \(url)")

      if invalidateAfterError,
         error.code == .cannotConnectToHost || error.code == .cannotFindHost || error
         .code == .dnsLookupFailed
      {
        logger.warning("NO HOST FOUND")
        Task {
          await serverLocator.invalidate(deviceInfo: deviceInfo)
        }
      }
//
      throw error
    } catch {
      logger.error("request error \(error), \(url)")
      throw error
    }
  }
}

extension InjectedValues {
  public var requestor: Requestor {
    get { Self[RequestorKey.self] }
    set { Self[RequestorKey.self] = newValue }
  }
}

private struct RequestorKey: InjectionKey {
  static var currentValue: Requestor = .init()
}
