//
//  SafariView.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 08/06/2021.
//

import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {
  let url: URL

  func makeUIViewController(context _: UIViewControllerRepresentableContext<SafariView>)
    -> SFSafariViewController
  {
    return SFSafariViewController(url: url)
  }

  func updateUIViewController(
    _: SFSafariViewController,
    context _: UIViewControllerRepresentableContext<SafariView>
  ) {}
}
