//
//  Capabilities.swift
//
//
//  Created by Tomas Harkema on 20/10/2023.
//

import Foundation

//{
//    "size: Int
//    "allowCameraUpload: Bool
//    "allowChannelAccess: Bool
//    "allowMediaDeletion: Bool
//    "allowSharing: Bool
//    "allowSync: Bool
//    "allowTuners: Bool
//    "backgroundProcessing: Bool
//    "certificate: Bool
//    "companionProxy: Bool
//    "countryCode: String
//    "diagnostics: String
//    "eventStream: Bool
//    "friendlyName: String
//    "hubSearch: Bool
//    "itemClusters: Bool
//    "livetv: Int
//    "machineIdentifier: String
//    "mediaProviders: Bool
//    "multiuser: Bool
//    "musicAnalysis: Int
//    "myPlex: Bool
//    "myPlexMappingState: String
//    "myPlexSigninState: String
//    "myPlexSubscription: Bool
//    "myPlexUsername: String
//    "offlineTranscode: Int
//    "ownerFeatures: String
//    "photoAutoTag: Bool
//    "platform: String
//    "platformVersion: String
//    "pluginHost: Bool
//    "pushNotifications: Bool
//    "readOnlyLibraries: Bool
//    "streamingBrainABRVersion: Int
//    "streamingBrainVersion: Int
//    "sync: Bool
//    "transcoderActiveVideoSessions: Int
//    "transcoderAudio: Bool
//    "transcoderLyrics: Bool
//    "transcoderPhoto: Bool
//    "transcoderSubtitles: Bool
//    "transcoderVideo: Bool
//    "transcoderVideoBitrates: String
//    "transcoderVideoQualities: String
//    "transcoderVideoResolutions: String
//    "updatedAt: Int
//    "updater: Bool
//    "version: String
//    "voiceSearch: Bool
//    "Directory": [
//      {
//        "count: Int
//        "key: String
//        "title": "string"
//      }
//    ]
//}

public struct Capabilities: Codable, Sendable, Equatable, Hashable {

  public let size: Int
  public let allowCameraUpload: Bool
  public let allowChannelAccess: Bool
  public let allowMediaDeletion: Bool
  public let allowSharing: Bool
  public let allowSync: Bool
  public let allowTuners: Bool
  public let backgroundProcessing: Bool
  public let certificate: Bool
  public let companionProxy: Bool
  public let countryCode: String
  public let diagnostics: String
  public let eventStream: Bool
  public let friendlyName: String
  public let hubSearch: Bool
  public let itemClusters: Bool
  public let livetv: Int
  public let machineIdentifier: String
  public let mediaProviders: Bool
  public let multiuser: Bool
  public let musicAnalysis: Int
  public let myPlex: Bool
  public let myPlexMappingState: String
  public let myPlexSigninState: String
  public let myPlexSubscription: Bool
  public let myPlexUsername: String
  public let offlineTranscode: Int
  public let ownerFeatures: String
  public let photoAutoTag: Bool?
  public let platform: String
  public let platformVersion: String
  public let pluginHost: Bool
  public let pushNotifications: Bool
  public let readOnlyLibraries: Bool
  public let streamingBrainABRVersion: Int
  public let streamingBrainVersion: Int
  public let sync: Bool
  public let transcoderActiveVideoSessions: Int
  public let transcoderAudio: Bool
  public let transcoderLyrics: Bool
  public let transcoderPhoto: Bool
  public let transcoderSubtitles: Bool
  public let transcoderVideo: Bool
  public let transcoderVideoBitrates: String
  public let transcoderVideoQualities: String
  public let transcoderVideoResolutions: String
  public let updatedAt: Int
  public let updater: Bool
  public let version: String
  public let voiceSearch: Bool
}
