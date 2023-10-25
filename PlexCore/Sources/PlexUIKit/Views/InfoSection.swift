//
//  InfoSection.swift
//
//
//  Created by Tomas Harkema on 23/10/2023.
//

import SwiftUI

struct InfoSection<ExtraType: View, ContentType: View>: View {
  @State
  private var collapsed = true

  private let title: String
  private let collapsible: Bool
  private let extra: () -> ExtraType
  private let content: () -> ContentType

  init(
    title: String,
    collapsible: Bool = false,
    @ViewBuilder extra: @escaping () -> ExtraType,
    @ViewBuilder content: @escaping () -> ContentType
  ) {
    self.title = title
    self.collapsible = collapsible
    self.extra = extra
    self.content = content
  }

  init(
    title: String,
    collapsible: Bool = false,
    @ViewBuilder content: @escaping () -> ContentType
  ) where ExtraType == EmptyView {
    self.title = title
    self.collapsible = collapsible
    extra = { EmptyView() }
    self.content = content
  }

  @ViewBuilder
  private var titleView: some View {
    Text(title)
      .font(.title2)
      .bold()
    Spacer()
    extra()
  }

  @ViewBuilder
  private var collapsibleVariantView: some View {
    Collapsible(
      collapsed: $collapsed,
      title: {
        titleView
      },
      content: {
        Divider()
        content()
      }
    )
    Divider()
  }

  @ViewBuilder
  private var nonCollapsibleVariantView: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(title)
          .font(.title2)
          .bold()
        Spacer()
        extra()
      }

      content()
    }
    Divider()
  }

  var body: some View {
    if collapsible {
      collapsibleVariantView
    } else {
      nonCollapsibleVariantView
    }
  }
}
