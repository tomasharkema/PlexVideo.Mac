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
import PlexShared

public final class Requestor {

  private let logger = Logger(subsystem: "PlexVideo", category: "Requestor")

  @Injected(\.serverLocator)
  private var serverLocator

  @Injected(\.requestorStorageProviding)
  private var storage: any RequestorStorageProviding

  func requestUrl(
    url: URL,
    queryItems: [URLQueryItem]? = nil,
    sendDefaultQueries: Bool = true
  ) async -> URL {
    let token = await storage.getToken()
    let uuid = await storage.uuid

    return await requestUrl(
      url: url,
      queryItems: queryItems,
      sendDefaultQueries: sendDefaultQueries,
      uuid: uuid,
      token: token
    )
  }

  @MainActor
  private func defaultQueryItems(
    deviceInfo _deviceInfo: DeviceInfo? = nil,
    uuid: String?,
    token: String?
  ) -> [URLQueryItem] {
    let deviceInfo = _deviceInfo ?? .current
    return [
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
      URLQueryItem(name: "X-Plex-Device-Name", value: deviceInfo.name)
    ]
  }

  @MainActor
  func requestUrl(
    url: URL,
    queryItems: [URLQueryItem]? = nil,
    sendDefaultQueries: Bool = true,
    uuid: String?,
    token: String?
  ) -> URL {

    var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
    let defaultQ = sendDefaultQueries ? defaultQueryItems(uuid: uuid, token: token) : []
    let extraItems = queryItems ?? []
    components.queryItems = (components.queryItems ?? []) + (defaultQ) + (extraItems)

    let url = components.url!

// #if DEBUG
//    logger.info("BUILT URL \(url)")
// #endif

    return url
  }

  nonisolated func request<DecodableType: Decodable>(
    url: URL,
    _ type: DecodableType.Type,
    method: String = "GET",
    queryItems: [URLQueryItem]? = nil,
    sendDefaultQueries: Bool = true,
    timeoutInterval: TimeInterval? = nil,
    invalidateAfterError: Bool = true,
    useCache: Bool = true
  ) async throws -> DecodableType {

    var mutualRequest =
      URLRequest(
        url: await requestUrl(
          url: url,
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
      let (data, response) = try await session.data(for: mutualRequest)

      try HTTPError.throwFor(urlResponse: response)

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
        return try JSONDecoder().decode(type, from: data)
      } catch {
        #if DEBUG
        logger.error("JSON ERROR:\nurl: \(url)\nerror: \(error)\njson: \(String(data: data, encoding: .utf8) ?? "")")
        #endif
        throw error
      }
    } catch let error as URLError {
      logger.error("request URLError \(error), \(String(describing: error.code)), \(url)")

      if invalidateAfterError,
         error.code == .cannotConnectToHost || error.code == .cannotFindHost || error
         .code == .dnsLookupFailed {
        logger.warning("NO HOST FOUND")
        Task {
          await serverLocator.invalidate()
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

@MainActor
public protocol RequestorStorageProviding {
  func getToken() -> String?
  var uuid: String { get }
}

public extension InjectedValues {
  var requestorStorageProviding: any RequestorStorageProviding {
    get { Self[RequestorStorageProvidingKey.self] }
    set { Self[RequestorStorageProvidingKey.self] = newValue }
  }
}

public struct RequestorStorageProvidingKey: InjectionKey {
  public static var currentValue: (any RequestorStorageProviding)?
}

extension InjectedValues {
  public var requestor: Requestor {
    get { Self[RequestorKey.self] }
    set { Self[RequestorKey.self] = newValue }
  }
}

private struct RequestorKey: InjectionKey {
  static var currentValue: Requestor? = .init()
}

// swiftlint:disable:next line_length
//      URLQueryItem(
//        name: "X-Plex-Client-Profile-Extra",
//        value:
// swiftlint:disable:next line_length
// "add-limitation(scope=videoAudioCodec&scopeName=*&type=upperBound&name=audio.channels&value=8&replace=true)+add-transcode-target(type=musicProfile&context=streaming&protocol=hls&container=mpegts&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3)+add-direct-play-profile(type=musicProfile&container=mp4&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3)+add-direct-play-profile(type=musicProfile&container=flac&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3)+add-transcode-target(type=videoProfile&context=streaming&protocol=hls&container=mp4&videoCodec=hevc&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3&id=hevcmp4)+add-transcode-target(type=videoProfile&context=streaming&protocol=hls&container=mpegts&videoCodec=h264&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3)+add-direct-play-profile(type=videoProfile&container=mp4,mov&videoCodec=h264,mpeg4&audioCodec=aac,aac_latm,ac3,alac,flac,dca,vorbis,opus,eac3,mp1,mp2,mp3&subtitleCodec=mov_text,tx3g,ttxt,text)"
//      ),
