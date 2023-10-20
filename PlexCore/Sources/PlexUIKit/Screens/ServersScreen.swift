//
//  ServersScreen.swift
//
//
//  Created by Tomas Harkema on 20/10/2023.
//

import SwiftUI
import PlexApi
import PlexShared

public struct ServersScreen: View {

  private let devices: [DeviceResponse]
  private let currentConnection: Connection?

  public init(devices: [DeviceResponse], currentConnection: Connection?) {
    self.devices = devices
    self.currentConnection = currentConnection
  }

  public var body: some View {
    List(devices) { device in
      Section(device.name) {
        ForEach(device.connections) { connection in
          HStack {
            Text(connection.address)
            if currentConnection == connection {
              Text("ACTIVE")
            }
          }
        }
      }
//      Section("Servers") {
//      Text(device.name)
//      }
    }
  }
}

//#Preview {
//  ServersScreen(devices: [], currentConnection: nil)
//}
