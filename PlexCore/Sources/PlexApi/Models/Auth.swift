//
//  Auth.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 09/06/2021.
//

import Dependencies
import Foundation
import OSLog
import PlexShared
import SwiftMacros

enum AuthError: LocalizedError {
  case limitReached
  case noUrl
}

@MainActor
public final class Auth {
  private let logger = Logger(subsystem: "PlexVideo", category: "Auth")

  @Dependency(\.authStorageProviding)
  private var storage

  @Dependency(\.requestor)
  private var requestor

  public nonisolated init() {}

  public func pollForPin(
    deviceInfo: DeviceInfo,
    pinId: String,
    requestDelay: Double,
    maxRetries: Int
  ) async throws -> String {
    try Task.checkCancellation()

    if maxRetries <= 0 {
      throw AuthError.limitReached
    }

    try await Task.sleep(for: .seconds(requestDelay))

    let deviceUuid = storage.uuid
    let urlRoot = #buildURL("https://plex.tv/api/v2/pins/").appendingPathComponent("\(pinId)")
//    let urlRoot = #buildURL("https://plex.tv/api/v2/pins/").appendingPathComponent("\(pinId)")
    var urlComponents = URLComponents(url: urlRoot, resolvingAgainstBaseURL: true)!
    urlComponents.queryItems =
      (urlComponents.queryItems ?? []) + [
        URLQueryItem(name: "X-Plex-Client-Identifier", value: deviceUuid),
        URLQueryItem(name: "X-Plex-Product", value: deviceInfo.product),
        URLQueryItem(name: "X-Plex-Platform", value: deviceInfo.platform),
        URLQueryItem(name: "X-Plex-Platform-Version", value: deviceInfo.version),
        URLQueryItem(name: "X-Plex-Device-Name", value: deviceInfo.product),
        URLQueryItem(name: "X-Plex-Version", value: deviceInfo.appVersion),
      ]

    let url = urlComponents.url!

    do {
      let token = try await requestor.request(
        url: url,
        PinToken.self,
        sendDefaultQueries: false,
        useCache: false
      )

      if let authToken = token.authToken {
        storage.plexToken = authToken
        return authToken
      } else {
        return try await pollForPin(
          deviceInfo: deviceInfo,
          pinId: pinId,
          requestDelay: min(20, requestDelay + 0.5),
          maxRetries: maxRetries - 1
        )
      }
    } catch let error as CancellationError {
      throw error
    } catch {
      logger.error("ERROR \(error)")

      return try await pollForPin(
        deviceInfo: deviceInfo,
        pinId: pinId,
        requestDelay: min(20, requestDelay + 0.5),
        maxRetries: maxRetries - 1
      )
    }
  }

  public func authUrl(deviceInfo: DeviceInfo) async throws -> (URL, String) {
    let deviceUuid = storage.uuid

    var urlComponents = URLComponents(string: "https://plex.tv/api/v2/pins")!
    urlComponents.queryItems =
      (urlComponents.queryItems ?? []) + [
        URLQueryItem(name: "X-Plex-Client-Identifier", value: deviceUuid),
        URLQueryItem(name: "X-Plex-Product", value: deviceInfo.product),
        URLQueryItem(name: "X-Plex-Platform", value: deviceInfo.platform),
        URLQueryItem(name: "X-Plex-Platform-Version", value: deviceInfo.version),
        URLQueryItem(name: "X-Plex-Device-Name", value: deviceInfo.product),
        URLQueryItem(name: "X-Plex-Version", value: deviceInfo.appVersion),
        URLQueryItem(name: "strong", value: "True"),
      ]

    let url = urlComponents.url!

    let data = try await requestor.request(
      url: url,
      PinToken.self,
      method: "POST",
      sendDefaultQueries: false,
      useCache: false
    )

    let urlWebRoot =
      #buildURL("https://app.plex.tv/auth/#!?") // URL(string: "https://app.plex.tv/auth/#!?")!
    var urlComponentsWeb = URLComponents(url: urlWebRoot, resolvingAgainstBaseURL: true)!
    urlComponentsWeb.queryItems =
      (urlComponents.queryItems ?? []) + [
        URLQueryItem(name: "clientID", value: data.clientIdentifier),
        URLQueryItem(name: "code", value: data.code),
        URLQueryItem(name: "context[device][product]", value: deviceInfo.product),
        URLQueryItem(name: "context[device][platform]", value: deviceInfo.platform),
        URLQueryItem(name: "context[device][platformVersion]", value: deviceInfo.version),
        URLQueryItem(name: "context[device][version]", value: deviceInfo.appVersion),
      ]

    let urlWeb = urlComponentsWeb.url!

    logger.info("received auth url: \(urlWeb)")

    let urlWebFixed = URL(
      string: urlWeb.absoluteString.replacingOccurrences(
        of: "auth/?",
        with: "auth/#!?"
      )
    )!

    try Task.checkCancellation()

    return (urlWebFixed, String(data.id))
  }
}

public extension DependencyValues {
  var auth: Auth {
    get { self[AuthKey.self] }
    set { self[AuthKey.self] = newValue }
  }
}

private struct AuthKey: DependencyKey {
  static var liveValue: Auth = .init()
}

public protocol AuthStorageProviding: AnyObject {
  var uuid: String { get }
  var plexToken: String? { get set }
}

public extension DependencyValues {
  var authStorageProviding: any AuthStorageProviding {
    get { self[AuthStorageProvidingKey.self] }
    set { self[AuthStorageProvidingKey.self] = newValue }
  }
}

public struct AuthStorageProvidingKey: TestDependencyKey {
  public static var testValue: (any AuthStorageProviding) = unimplemented()
}
