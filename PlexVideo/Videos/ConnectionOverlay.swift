//
//  ConnectionOverlay.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 09/06/2021.
//

import Foundation
import SwiftUI

struct ConnectionOverlay: View {
  @State var showOverlay: Bool = false
  @StateObject var connection = ServerLocator.locator

  var body: some View {
    Rectangle().foregroundColor(.clear).overlay(
      HStack {
        if let connection = connection.connection {
          Text("\(connection.local ? "Local" : "Remote") connection")
            .font(.subheadline.bold().lowercaseSmallCaps())
            .foregroundColor(.white)
            .edgesIgnoringSafeArea(.top)
            .padding(5)
            .background(connection.local ? Color.green : Color.yellow)
            .cornerRadius(10)
            .onAppear {
              let old = self.connection.connection
              showOverlay = true
              DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if old == self.connection.connection {
                  showOverlay = false
                }
              }
            }
        }
      }
      .onChange(of: connection.connection) {
        showOverlay = $0 != nil
      }
      .offset(y: showOverlay ? 10 : -100)
      .opacity(showOverlay ? 1 : 0)
      .animation(.easeInOut, value: connection.connection)
      .animation(.easeInOut, value: showOverlay),
      alignment: .top
    )
  }
}
