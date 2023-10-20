//
//  Login.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 27/05/2021.
//

import AuthenticationServices
import Foundation
import SwiftUI
import Inject
import PlexApi
import PlexCore
import PlexShared

struct Login: View {
  @StateObject
  private var viewModel = LoginViewModel()

  @MainActor
  private func loginButton() -> some View {
    Button("Login", action: {
      Task {
        await viewModel.login(deviceInfo: DeviceInfo.current)
      }
    })
  }

  var body: some View {
    VStack {
      switch viewModel.loginState {
      case .absent:
        loginButton()

      case .loading:
        VStack {
          ProgressView()    
          Button("Cancel", action: {
            viewModel.cancel()
          })
        }

      case .loaded:
        EmptyView()

      case .error(let error):
        VStack {
          Text(error.localizedDescription)
          loginButton()
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onDisappear {
      viewModel.cancel()
    }
  }
}
