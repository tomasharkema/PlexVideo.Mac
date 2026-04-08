//
//  PlexWebPinEndpoint.swift
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
package protocol PlexWebPinEndpoint {
  @GET("/pins/:pin")
  func pins(pin: Path<String>) async throws -> PinToken
}

extension DependencyValues {
  var plexWebPinEndpoint: any PlexWebPinEndpointProviderProtocol {
    get { self[PlexWebPinEndpointAPIKey.self] }
    set { self[PlexWebPinEndpointAPIKey.self] = newValue }
  }
}

package protocol PlexWebPinEndpointProviderProtocol: Sendable {
  func provider() async -> PlexWebPinEndpointAPI
}

struct TestPlexWebPinEndpointProviderProtocol: PlexWebPinEndpointProviderProtocol {
  func provider() async -> PlexWebPinEndpointAPI { fatalError() }
}

struct PlexWebPinEndpointAPIKey: TestDependencyKey {
  static let testValue: any PlexWebPinEndpointProviderProtocol =
    TestPlexWebPinEndpointProviderProtocol()
}

extension PlexWebPinEndpointAPIKey: DependencyKey {
  package static let liveValue: any PlexWebPinEndpointProviderProtocol =
    PlexWebPinEndpointProvider()
}
