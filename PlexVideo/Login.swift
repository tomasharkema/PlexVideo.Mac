//
//  Login.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import AuthenticationServices
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
  }
}

@MainActor
class LoginViewModel: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
  @Published var url: URL?

  private var loginTask: Task.Handle<Void, Error>?
  private var d: ASWebAuthenticationSession?

  func login() {
    loginTask = async {
      let (url, pin) = try await Auth.shared.authUrl()
      print(url)
      self.url = url
      d = ASWebAuthenticationSession(url: url, callbackURLScheme: "plexvideo", completionHandler: {
        print($0, $1)
      })
      d?.presentationContextProvider = self
      d?.start()
      let token = try await Auth.shared.pollForPin(pinId: pin, requestDelay: 1, maxRetries: 1000)
      d?.cancel()
      self.url = nil
      print(token)
      Storage.shared.plexToken = token
    }
  }

  func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }

  func cancel() {
    loginTask?.cancel()
  }
}
