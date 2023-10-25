//
//  Previews.swift
//
//
//  Created by Tomas Harkema on 24/10/2023.
//

import Foundation
import PlexShared

public struct NullError: Error {
  public init() { }
}

#if DEBUG

  extension Server {
    static let preview: [Server] = {
      let decoder = JSONDecoder.default
      decoder.dateDecodingStrategy = .formatted(.iso8601Full)

      let previewURL = Bundle.module.url(forResource: "server", withExtension: "json")!
      // swiftlint:disable:next force_try
      let previewString = try! Data(contentsOf: previewURL)

//    let previewString = Data(PackageResources.server_json)

      // swiftlint:disable:next force_try
      return try! decoder.decode(
        [Server].self,
        from: previewString
      )
    }()
  }

  public extension Server {
    static let preview1 = Server.preview[0]

//  public static let preview2 = Server.preview[1]
  }

  public extension ServerAndCapabilities {
    static let preview1 = ServerAndCapabilities(
      server: .preview1,
      capabilities: .failure(NullError())
    )
  }

  extension ServerWithCurrentConnection {
    static let preview1 = ServerWithCurrentConnection(server: .preview1, connection: .preview3)
  }

  public extension Connection {
    //  public static let preview1 = Connection(
    //    protocol: "https",
    //    address: "1.2.3.4",
    //    port: 8080,
    //    uri: URL(string: "https://1.2.3.4")!,
    //    local: true,
    //    relay: false,
    //    IPv6: false
    //  )
    //
    //  public static let preview2 = Connection(
    //    protocol: "https",
    //    address: "5.6.7.8",
    //    port: 8080,
    //    uri: URL(string: "https://5.6.7.8")!,
    //    local: false,
    //    relay: false,
    //    IPv6: false
    //  )

    static let preview3 = Server.preview1.connections[0]
  }

  public extension SessionStatus {
    static let preview: SessionStatus = {
      let decoder = JSONDecoder.default
      decoder.dateDecodingStrategy = .formatted(.iso8601Full)

      let previewURL = Bundle.module.url(forResource: "session", withExtension: "json")!
      // swiftlint:disable:next force_try
      let previewString = try! Data(contentsOf: previewURL)

//    let previewString = Data(PackageResources.session_json)

      // swiftlint:disable:next force_try
      return try! decoder.decode(
        SessionStatus.self,
        from: previewString
      )
    }()
  }

  public extension Video {
    static let preview: Video = {
      let decoder = JSONDecoder.default
      decoder.dateDecodingStrategy = .formatted(.iso8601Full)

      let previewURL = Bundle.module.url(forResource: "video", withExtension: "json")!
      // swiftlint:disable:next force_try
      let previewString = try! Data(contentsOf: previewURL)

//    let previewString = Data(PackageResources.video_json)

      // swiftlint:disable:next force_try
      return try! decoder.decode(
        Video.self,
        from: previewString
      )
    }()
  }

  public extension VideoFromServer {
    static let preview: VideoFromServer = .init(
      video: .preview,
      server: .preview1
    )
  }

#endif
