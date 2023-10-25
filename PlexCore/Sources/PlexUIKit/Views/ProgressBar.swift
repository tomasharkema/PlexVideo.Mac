//
//  ProgressBar.swift
//
//
//  Created by Tomas Harkema on 25/10/2023.
//

import PlexShared
import SwiftUI

public struct ProgressBar: View {
  private let video: Video

  public init(video: Video) {
    self.video = video
  }

  public var body: some View {
    if let viewOffset = video.viewOffset?.value,
       let duration = video.media?.first?.duration.value
    {
      GeometryReader { proxy in
        HStack {
          Rectangle()
            .foregroundColor(PublicColor.plexTint)
            .frame(
              width: proxy.size.width * (viewOffset / duration),
              height: 5,
              alignment: .leading
            )
          Spacer()
        }
        .background(Color.black.opacity(0.2))
        .frame(height: 5)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 5)
    }
  }
}
