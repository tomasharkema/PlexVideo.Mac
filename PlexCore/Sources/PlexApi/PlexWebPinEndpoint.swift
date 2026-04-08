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
public protocol PlexWebPinEndpoint {
  @GET("/pins/:pin")
  func pins(pin: Path<String>) async throws -> PinToken
}

extension DependencyValues {
  var plexWebPinEndpoint: any PlexWebPinEndpointProviderProtocol {
    get { self[PlexWebPinEndpointAPIKey.self] }
    set { self[PlexWebPinEndpointAPIKey.self] = newValue }
  }
}

public protocol PlexWebPinEndpointProviderProtocol: Sendable {
  func provider() async -> PlexWebPinEndpointAPI
}

struct TestPlexWebPinEndpointProviderProtocol: PlexWebPinEndpointProviderProtocol {
  func provider() async -> PlexWebPinEndpointAPI { fatalError() }
}

public struct PlexWebPinEndpointAPIKey {
}

extension PlexWebPinEndpointAPIKey: TestDependencyKey {
  public static let testValue: any PlexWebPinEndpointProviderProtocol =
    TestPlexWebPinEndpointProviderProtocol()
}
