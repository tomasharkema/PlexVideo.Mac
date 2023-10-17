//
//  LoginViewModel.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 16/10/2023.
//

import AuthenticationServices
import Foundation
import SwiftUI
import AsyncAwaitHelpers
import Inject
import PlexApi
import Processed
import OSLog

@MainActor
public final class LoginViewModel: NSObject, ObservableObject, LoadableSupport, ASWebAuthenticationPresentationContextProviding {

  private var logger = Logger(subsystem: "PlexVideo", category: "LoginViewModel")

  @Injected(\.auth)
  private var auth

  @Injected(\.storage)
  private var storage

  @Published 
  public private(set) var url: URL?

  private var authSession: ASWebAuthenticationSession?

  @Published
  public private(set) var loginState: LoadableState<Void> = .absent

  public override init() {
    super.init()
  }

  private nonisolated func gotSessionError(error: any Error) {
    Task { @MainActor in
      logger.error("session error: \(error)")
      if !loginState.isLoaded {
        loginState = .error(error)
      }
    }
  }

  public func login(deviceInfo: DeviceInfo) async {
    await self.load(\.loginState, priority: .medium) {

      let (url, pin) = try await self.auth.authUrl(deviceInfo: deviceInfo)
      
      self.url = url

      self.authSession = ASWebAuthenticationSession(
        url: url,
        callbackURLScheme: "plexvideo",
        completionHandler: { [weak self] url, error in
          if let error = error {
            self?.gotSessionError(error: error)
          }
        }
      )
      
      self.authSession?.presentationContextProvider = self
      self.authSession?.start()

      let token = try await self.auth.pollForPin(
        deviceInfo: deviceInfo,
        pinId: pin,
        requestDelay: 1,
        maxRetries: 1000
      )

      if !Task.isCancelled, self.storage.plexToken == nil {
        self.storage.plexToken = token
      }

      self.authSession?.cancel()
      self.authSession = nil
      self.url = nil

      try Task.checkCancellation()
    }.value
  }

  public func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
    ASPresentationAnchor()
  }

  public func cancel() {
    self.cancel(\.loginState)
  }
}
