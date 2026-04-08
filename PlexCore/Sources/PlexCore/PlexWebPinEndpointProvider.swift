//
//  PlexWebPinEndpointProvider.swift
//
//
//  Created by Tomas Harkema on 28/10/2023.
//

import Dependencies
import Foundation
import Papyrus
import PlexApi
import PlexShared

package struct PlexWebPinEndpointProvider: PlexWebPinEndpointProviderProtocol {
  @Dependency(\.storage)
  private var storage

  package func provider() async -> PlexWebPinEndpointAPI {
    let provider = Provider(baseURL: "https://plex.tv/api/v2")

    let deviceInfo = await DeviceInfo.current
    let plexToken = await storage.plexToken
    let uuid = await storage.uuid

    provider.modifyRequests { req in

      req.addHeaders([
        "X-MetricsUUID": UUID().uuidString,
        "Accept": "application/json",
      ])

      req.addQuery("X-Plex-Client-Identifier", value: uuid)
      req.addQuery("X-Plex-Product", value: deviceInfo.product)
      req.addQuery("X-Plex-Platform", value: deviceInfo.platform)
      req.addQuery("X-Plex-Platform-Version", value: deviceInfo.version)
      req.addQuery("X-Plex-Device-Name", value: deviceInfo.product)
      req.addQuery("X-Plex-Version", value: deviceInfo.appVersion)

      //      req.addQuery("X-Plex-Client-Identifier", value: uuid)
      //      req.addQuery("X-Plex-Client-Platform", value: deviceInfo.platform)
      //      req.addQuery("X-Plex-Device", value: deviceInfo.device)
      //      req.addQuery("X-Plex-Device-Screen-Density", value: "3")
      //      req.addQuery("X-Plex-Device-Screen-Resolution", value: "1920x1080")
      //      req.addQuery("X-Plex-Device-Vendor", value: "Apple")
      //      req.addQuery("X-Plex-Model", value: "13,4")
      //      req.addQuery("X-Plex-Platform", value: deviceInfo.platform)
      //      req.addQuery("X-Plex-Platform-Version", value: deviceInfo.version)
      //      req.addQuery("X-Plex-Product", value: deviceInfo.product)
      //      req.addQuery("X-Plex-Sync-Version", value: "2")
      //      req.addQuery("X-Plex-Token", value: plexToken)
      //      req.addQuery("X-Plex-Username", value: "teumaauss")
      //      req.addQuery("X-Plex-Version", value: deviceInfo.appVersion)
      //      req.addQuery("X-Plex-Language", value: "nl")
      //      req.addQuery("X-Plex-Device-Name", value: deviceInfo.name)
    }

    return PlexWebPinEndpointAPI(provider: provider)
  }
}
