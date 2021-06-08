//
//  Login.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import Foundation
import SwiftUI

struct Login: View {
  @StateObject var viewModel = LoginViewModel()
  @State var showSafari: Bool = false

  var body: some View {
    Button("Login", action: {
      viewModel.login()
    })
      .onDisappear {
        viewModel.cancel()
      }
      .onChange(of: viewModel.url) {
        showSafari = $0 != nil
      }
      .onChange(of: showSafari) {
        if !$0 {
          viewModel.cancel()
        }
      }
      .sheet(isPresented: $showSafari) {
        if let url = viewModel.url {
          SafariView(url: url)
        }
      }
  }
}

@MainActor
class LoginViewModel: ObservableObject {
  @Published var url: URL?

  private var loginTask: Task.Handle<Void, Error>?

  func login() {
    loginTask = async {
      let (url, pin) = try await Api.shared.authUrl()
      print(url)
      self.url = url
      let token = try await Api.shared.pollForPin(pinId: pin, requestDelay: 1, maxRetries: 1000)
      self.url = nil
      print(token)
      Storage.shared.plexToken = token
    }
  }

  func cancel() {
    loginTask?.cancel()
  }
}
