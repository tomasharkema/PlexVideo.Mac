//
//  SessionVideo.swift
//
//
//  Created by Tomas Harkema on 24/10/2023.
//

import Foundation
import PlexApi
import PlexShared

public struct SessionVideo: Sendable {
  public let video: VideoFromServer
  public let session: SessionStatus

  public init(video: VideoFromServer, session: SessionStatus) {
    self.video = video
    self.session = session
  }
}

extension SessionVideo: Identifiable {
  public var id: VideoFromServer.ID {
    video.id
  }
}
