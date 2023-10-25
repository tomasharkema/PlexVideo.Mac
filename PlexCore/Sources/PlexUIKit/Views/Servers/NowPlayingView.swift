//
//  NowPlayingView.swift
//
//
//  Created by Tomas Harkema on 24/10/2023.
//

import PlexApi
import PlexCore
import PlexShared
import SwiftUI

struct NowPlayingView: View {
  @Environment(\.hostingWindowSize)
  private var hostingWindowSize

  private let session: SessionVideo

  init(session: SessionVideo) {
    self.session = session
  }

  private var playingStateString: String? {
    session.playerState.map { "\($0.localizedCapitalized)" }
  }

  private var durationString: String? {
    guard let duration = session.duration,
          let offsetFormat = Self.timeFormatter.string(from: session.viewOffset),
          let durationFormat = Self.timeFormatter.string(from: duration)
    else {
      return nil
    }

    return "\(offsetFormat) / \(durationFormat)"
  }

  private var playingStateCombined: String? {
    let items = [playingStateString, durationString]
      .compactMap { $0 }
    guard !items.isEmpty else {
      return nil
    }
    return items.joined(separator: " — ")
  }

  @ViewBuilder
  private func playingState(session _: SessionVideo) -> some View {
    if let playingStateCombined {
      Text(playingStateCombined)
        .foregroundColor(.white.opacity(0.6))
    }
  }

  @ViewBuilder
  private func progressText(session: SessionVideo) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      if let player = session.session.player?.value {
        Text("\(player.product) — \(player.device ?? player.title)")
          .lineLimit(1)
      }

      playingState(session: session)

      if let player = session.session.player?.value,
         let bandwidthMbps = session.bandwidthMbps
      {
        Text("\(player.local ? "Local" : "Remote") (\(player.address)) — \(bandwidthMbps)")
          .foregroundColor(.white.opacity(0.6))
      }
    }
  }

  @ViewBuilder
  private func transcodeState(session: SessionStatus) -> some View {
    Grid(
      alignment: .leadingFirstTextBaseline,
      horizontalSpacing: 10,
      verticalSpacing: 5
    ) {
      GridRow {
        Text("Video")
          .foregroundColor(.white.opacity(0.6))

        VStack(alignment: .leading, spacing: 5) {
          Text("\(session.videoSourceString)")
          Text("\(Image(systemName: "arrow.turn.down.right")) \(session.videoString)")
        }
      }
      GridRow {
        Text("Audio")
          .foregroundColor(.white.opacity(0.6))

        VStack(alignment: .leading, spacing: 5) {
          Text("\(session.audioSourceString)")
          Text("\(Image(systemName: "arrow.turn.down.right"))  \(session.audioString)")
        }
      }
      if let subtitleString = session.subtitleString {
        GridRow {
          Text("Subtitles")
            .foregroundColor(.white.opacity(0.6))
          Text("\(subtitleString)")
        }
      }
    }.font(.footnote)
  }

  @ViewBuilder
  private func userState(session: SessionStatus) -> some View {
    if let user = session.user?.value {
      HStack(spacing: 20) {
        if let thumb = user.thumb {
          AsyncImage(url: thumb) { image in
            image.resizable()
          } placeholder: {
            Color.clear
          }
          .frame(width: 40, height: 40)
          .cornerRadius(40)
        }
        Text(user.title)
        Spacer()
      }
    }
  }

  @MainActor
  private var smallUI: Bool {
    hostingWindowSize.width < 900
  }

  var body: some View {
    HStack {
      let size = if smallUI {
        CGSize(width: 67, height: 104)
      } else {
        ThumbViewModel.thumbSize
      }

      VStack(alignment: .leading, spacing: 0) {
        VStack(spacing: 0) {
          HStack {
            Thumb(video: session.video, size: size)
            VStack(alignment: .leading, spacing: smallUI ? 5 : 20) {
              Text(session.video.video.title)
                .font(.headline.bold())
              if let year = session.video.video.year?.value {
                Text("\(year as NSNumber, formatter: Self.yearFormatter)")
                  .foregroundColor(.white.opacity(0.6))
              }
              if let duration = session.video.video.duration {
                Text("\(Self.durationFormatter.string(from: duration / 1000) ?? "")")
                  .foregroundColor(.white.opacity(0.6))
              }
            }.padding()
            Spacer()
          }
          .background(.black.opacity(0.6))

          ProgressBar(video: session.video.video)
        }

        progressText(session: session)
          .padding()

        HStack {
          transcodeState(session: session.session)
            .padding()
          Spacer()
        }
        .background(Color(.black).opacity(0.2))

        userState(session: session.session)
          .padding()
          .frame(maxWidth: .infinity)
          .background(Color(.black).opacity(0.4))
      }
    }
    .background(Color(.plexTint).opacity(0.3))
    .cornerRadius(10)
  }
}

extension NowPlayingView {
  private static let timeFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .positional
    formatter.zeroFormattingBehavior = .pad
    formatter.allowedUnits = [.hour, .minute, .second]
    return formatter
  }()

  private static let durationFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .short
    formatter.zeroFormattingBehavior = .pad
    formatter.allowedUnits = [.hour, .minute, .second]
    return formatter
  }()

  private static let yearFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .none
    return formatter
  }()
}

#if DEBUG
  #Preview {
    NowPlayingView(
      session: SessionVideo(
        video: .preview,
        session: .preview
      )
    )
    .padding()
    .preferredColorScheme(.dark)
  }
#endif
