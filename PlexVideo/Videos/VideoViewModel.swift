//
//  VideosViewModel.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import Foundation

@MainActor
class VideosViewModel: ObservableObject {
  struct Data: Equatable {
    let continueWatching: [Video]
    let videos: [Video]
  }

  @Published private(set) var data: Data?
  @Published private(set) var savedLastPlayed: Video?

  func load() async throws {
    guard let token = Storage.plexToken else {
      return
    }

    savedLastPlayed = try? await Storage.getLastPlayed()

    let videos = try await Api.shared.videos(token: token)

    let offsets: [String: Progress] = try await asyncDetached(priority: .default, operation: {
      var offsets = [String: Progress]()
      for var v in videos {
        if let d = v.getProgress(storage: try await Storage.getSavedOffset(video: v)) {
          offsets[v.key] = d
        }
      }
      return offsets
    }).getResult().get()

    data = try await asyncDetached(priority: .default) {
      let cont = videos.lazy.map {
        ($0, offsets[$0.key])
      }.filter {
        $0.1?.date != nil
      }.map {
        $0.0
      }.sorted {
        $0.lastViewedAt?.value ?? 0 > $1.lastViewedAt?.value ?? 0
      }
      return Data(continueWatching: cont, videos: videos)
    }.getResult().get()
  }
}
