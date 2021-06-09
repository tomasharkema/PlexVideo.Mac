//
//  Thumb.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import SwiftUI

struct Thumb: View {
  let video: Video
  let width: CGFloat?
  let height: CGFloat?

  @State var url: URL?

  var body: some View {
    AsyncImage(url: url, content: { (i: Image) in
      i.resizable()
        .frame(width: width, height: height)
    }) {
      Rectangle().foregroundColor(.clear).background(Color.clear)
        .frame(width: width, height: height)
    }
    .background(Color.black.opacity(0.6))
    .frame(width: width, height: height)
    .onAppear {
      async {
        url = try await Api.shared.imageUrl(
          item: video,
          token: Storage.shared.plexToken ?? "",
          width: Int(width ?? 120) * 2,
          height: Int(height ?? 180) * 2
        )
      }
    }
  }
}
