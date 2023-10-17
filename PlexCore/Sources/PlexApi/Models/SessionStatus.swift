//
//  SessionStatus.swift
//  
//
//  Created by Tomas Harkema on 17/10/2023.
//

import Foundation
import MetaCodable
import PlexShared

@Codable
struct SessionStatus {
  @CodedAt("Player")
  let player: Player

  @CodedAt("Session")
  let session: Session

  @CodedAt("TranscodeSession")
  let transcodeSession: TranscodeSession
}
