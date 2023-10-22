//
//  Model.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 06/06/2021.
//

import Foundation
import MetaCodable
import PlexShared

struct Player: Codable {
  let machineIdentifier: String
  let address: String
}

struct Session: Codable {
  let id: String
  let bandwidth: Int
}

struct PinToken: Codable {
  let authToken: String?
  let clientIdentifier: String
  let code: String
  let createdAt: String?
  let expiresAt: String?
  let expiresIn: NumberLike?
  let id: Int
  let newRegistration: Bool?
  let product: String?
  let trusted: Bool?
  /*
   authToken: string | null,
   clientIdentifier: string,
   code: string,
   createdAt: string,
   expiresAt: string,
   expiresIn: number,
   id: number,
   location: IPlexCodeLocation,
   newRegistration:boolean | null,
   product: string,
   trusted: boolean
   */
}
