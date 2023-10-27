//
//  LoginViewModel.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 16/10/2023.
//

import AuthenticationServices
import Dependencies
import Foundation
import OSLog
import PlexApi
import PlexShared
import Processed
import SwiftUI

@MainActor
public final class LoginViewModel: NSObject, ObservableObject, LoadableSupport,
  ASWebAuthenticationPresentationContextProviding
{
  private var logger = Logger(subsystem: "PlexVideo", category: "LoginViewModel")

  @Dependency(\.auth)
  private var auth

  @Dependency(\.storage)
  private var storage

  @Published
  public private(set) var url: URL?

  private var authSession: ASWebAuthenticationSession?

  @Published
  public private(set) var loginState: LoadableState<Void> = .absent

  override public init() {
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
    await load(\.loginState, priority: .medium) {
      let (url, pin) = try await self.auth.authUrl(deviceInfo: deviceInfo)

      self.url = url

      self.authSession = ASWebAuthenticationSession(
        url: url,
        callbackURLScheme: "plexvideo",
        completionHandler: { [weak self] _, error in
          if let error {
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

  @MainActor
  public func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
    ASPresentationAnchor()
  }

  public func cancel() {
    cancel(\.loginState)
  }
}
