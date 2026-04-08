//
//  Collapsible.swift
//
//
//  Created by Tomas Harkema on 23/10/2023.
//

import SwiftUI

public struct Collapsible<TitleViewType: View, ContentViewType: View>: View {
  @Binding
  private var collapsed: Bool
  private let transaction: Transaction
  private let title: () -> TitleViewType
  private let content: () -> ContentViewType

  init(
    collapsed: Binding<Bool>,
    transaction: Transaction = .init(animation: .easeInOut),
    @ViewBuilder title: @escaping () -> TitleViewType,
    @ViewBuilder content: @escaping () -> ContentViewType
  ) {
    _collapsed = collapsed
    self.transaction = transaction
    self.title = title
    self.content = content
  }

  public var body: some View {
    VStack(alignment: .leading) {
      HStack {
        title()
        Spacer()
        Text("v")
//        Text("\(SFSymbol.chevronDown.image())")
          .font(.title2)
          .rotationEffect(.degrees(collapsed ? -90 : 0))
      }.onTapGesture {
        withTransaction(transaction) {
          collapsed.toggle()
        }
      }
      if !collapsed {
        content()
      }
    }
  }
}
