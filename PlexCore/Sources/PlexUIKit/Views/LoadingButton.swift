//
//  LoadingButton.swift
//
//
//  Created by Tomas Harkema on 19/10/2023.
//

import SwiftUI

public struct LoadingButton<TextViewType: View, LoadingTextViewType: View>: View {
  public let text: () -> TextViewType
  public let loadingText: () -> LoadingTextViewType
  public let priority: TaskPriority
  public let action: @Sendable () async -> Void

  @State
  public private(set) var isExecuting = false

  public init(
    @ViewBuilder text: @escaping () -> TextViewType,
    @ViewBuilder loadingText: @escaping () -> LoadingTextViewType,
    priority: TaskPriority = .userInitiated,
    action: @escaping @Sendable () async -> Void
  ) {
    self.text = text
    self.loadingText = loadingText
    self.priority = priority
    self.action = action
  }

  public var body: some View {
    Button {
      if !isExecuting {
        isExecuting = true
      }
    } label: {
      if isExecuting {
        loadingText()
      } else {
        text()
      }
    }
    .disabled(isExecuting)
    .task(id: isExecuting, priority: priority) {
      if isExecuting {
        defer { isExecuting = false }
        await action()
      }
    }
  }
}

// extension LoadButton {
//  @ViewBuilder
//  public static func defaultLoadingButton(
//    priority: TaskPriority = .userInitiated,
//    action: @escaping @Sendable () async -> Void
//  ) -> some View {
//    LoadButton(
//      text: { Image(systemName: "arrow.clockwise") },
//      loadingText: { ProgressView() },
//      priority: priority
//    ) {
//      await action
//    }
//  }
// }
