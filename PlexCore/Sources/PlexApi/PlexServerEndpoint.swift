import Dependencies
import Foundation
import Papyrus
import PlexShared

@API
@JSON(decoder: .default)
package protocol PlexServerEndpoint {
  @GET("/library/sections")
  func sections() async throws -> Root<DirectoryContainer>

  @GET("/library/sections/:key/all")
  func section(key: SectionKey.RawValue) async throws -> Root<Metadata<Video>>

  @GET("/library/metadata/:ratingKey?includeOnDeck=1")
  func metadata(ratingKey: RatingKey.RawValue) async throws -> Root<Metadata<Video>>

  @GET("/status/sessions")
  func sessions() async throws -> Root<Metadata<SessionStatus>>

  @GET("/:/timeline?context=library%3Acontent.library")
  func timeline(
    time: Query<Int>,
    ratingKey: Query<String>,
    duration: Query<Int>,
    state: Query<String>,
    key: Query<String>
  ) async throws -> Root<TranscodeSessions>

  @GET("/hubs/continueWatching?includeMeta=1")
  func continueWatching(
    contentDirectoryID: Query<String>
  ) async throws -> Root<Hub<Video>>

  @GET("/myplex/account")
  func userProfile() async throws -> UserProfileResponse
}

extension DependencyValues {
  package var plexServerEndpoint: any PlexServerEndpointProviderProtocol {
    get { self[PlexServerEndpointAPIKey.self] }
    set { self[PlexServerEndpointAPIKey.self] = newValue }
  }
}

package protocol PlexServerEndpointProviderProtocol: Sendable {
  func provider(server: ServerWithCurrentConnection) async -> PlexServerEndpointAPI
}

final class TestPlexServerEndpointProviderProtocol: PlexServerEndpointProviderProtocol {
  func provider(server: ServerWithCurrentConnection) async -> PlexServerEndpointAPI {
    fatalError()
  }
}

package struct PlexServerEndpointAPIKey: TestDependencyKey {
  package static let testValue: any PlexServerEndpointProviderProtocol =
    TestPlexServerEndpointProviderProtocol()
}
