//
//  PlexWebEndpoint.swift
//
//
//  Created by Tomas Harkema on 27/10/2023.
//

import Dependencies
import Foundation
import Papyrus
import PlexShared

@API
@JSON(decoder: .default)
package protocol PlexWebEndpoint {
  @GET("/resources?includeHttps=1&includeRelay=1")
  func resources() async throws -> [Server]

  @GET("/user")
  func userProfile() async throws -> UserProfileResponse
}

extension DependencyValues {
  package var plexWebEndpoint: any PlexWebEndpointProviderProtocol {
    get { self[PlexWebEndpointAPIKey.self] }
    set { self[PlexWebEndpointAPIKey.self] = newValue }
  }
}

package protocol PlexWebEndpointProviderProtocol: Sendable {
  func provider() async -> PlexWebEndpointAPI
}

final class TestPlexWebEndpointProvider: PlexWebEndpointProviderProtocol {
  func provider() async -> PlexWebEndpointAPI {
    fatalError()
  }
}

package struct PlexWebEndpointAPIKey: TestDependencyKey {
  package static let testValue: any PlexWebEndpointProviderProtocol = TestPlexWebEndpointProvider()
}
