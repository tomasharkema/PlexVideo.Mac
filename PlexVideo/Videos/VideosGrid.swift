//
//  VideosGrid.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import SwiftUI

struct VideosGrid: View {
  @StateObject var viewModel: VideosViewModel

  @Binding var video: Video?

  private func section(text: String, videos: [Video]) -> some View {
    VStack(alignment: .leading) {
      Text(text).font(Font.system(size: 32, weight: .semibold, design: .default)).padding()

      LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 50) {
        ForEach(videos) { video in
          Button(
            action: {
              async {
                let newVideo = try await viewModel.openVideo(video: video)
                withAnimation {
                  self.video = newVideo
                }
              }
            },
            label: {
              VideoListItem(video: video, width: 120, height: 180, activeVideo: $video)
            }
          )
          .buttonStyle(PlainButtonStyle())
        }
      }
    }
  }

  var body: some View {
    ScrollView {
      if let data = viewModel.data {
        VStack(alignment: .leading) {
          switch data {
          case let .success(data):
            section(text: "Continue Watching", videos: data.continueWatching)
            Spacer()
            section(text: "All", videos: data.videos)

          case let .failure(error):
            Text(error.localizedDescription)
          }
        }
        .padding()
        .animation(.easeInOut(duration: 0.6), value: data)
        .navigationBarItems(trailing: HStack { Button("Reload", action: {
          async {
            try await viewModel.load()
          }
        })
        Button("Logout", action: {
          Storage.shared.plexToken = nil
        })
        })
        .navigationBarTitle(Text("Videos"), displayMode: .inline)
      }
    }.refreshable {
      async {
        try await viewModel.load()
      }
    }
  }
}
