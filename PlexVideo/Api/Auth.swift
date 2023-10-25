//
//  Auth.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 09/06/2021.
//

import Foundation

enum AuthError: LocalizedError {
  case limitReached
  case noUrl
}

class Auth {
  static let shared = Auth()
  private let requestor = Requestor.shared

  func pollForPin(pinId: Int, requestDelay: Double, maxRetries: Int) async throws -> String {
    try Task.checkCancellation()

    if maxRetries <= 0 {
      throw AuthError.limitReached
    }

    try await Task.sleep(time: requestDelay)

    do {
      let token: PinToken = await try await requestor.request(
        url: URL(
          string:
          "https://plex.tv/api/v2/pins/\(pinId)?X-Plex-Client-Identifier=\(Storage.shared.uuid)&X-Plex-Product=\(DeviceInfo.shared.product)&X-Plex-Platform=\(DeviceInfo.shared.platform)&X-Plex-Platform-Version=\(DeviceInfo.shared.version)&X-Plex-Device-Name=\(DeviceInfo.shared.product)&X-Plex-Version=\(DeviceInfo.shared.appVersion)"
        )!,
        sendDefaultQueries: false
      )

      if let authToken = token.authToken {
        await MainActor.run {
          Storage.shared.plexToken = authToken
        }
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
    let data: PinToken = await try await requestor.request(
      url: URL(
        string:
        "https://plex.tv/api/v2/pins?X-Plex-Client-Identifier=\(Storage.shared.uuid)&X-Plex-Product=\(DeviceInfo.shared.product)&X-Plex-Platform=\(DeviceInfo.shared.platform)&X-Plex-Platform-Version=7&X-Plex-Device-Name=\(DeviceInfo.shared.product)&X-Plex-Version=3.2.2.5080&strong=True"
      )!,
      method: "POST",
      sendDefaultQueries: false
    )

    let url =
      "https://app.plex.tv/auth/#!?clientID=\(data.clientIdentifier)&code=\(data.code)&context[device][product]=\(DeviceInfo.shared.product)&context[device][platform]=\(DeviceInfo.shared.platform)&context[device][platformVersion]=7&context[device][version]=3.2.2.5080"

    guard
      let url = URL(
        string: url
      )
    else {
      throw AuthError.noUrl
    }
    print(url)
    return (url, Int(data.id.value))
  }
}
