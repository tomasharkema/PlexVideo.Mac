//
//  PlayerOverlay.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 07/06/2021.
//

import SwiftUI

struct PlayerOverlay: View {
  @Binding var state: ViewState
  @State var pip = false

  struct ViewState: Equatable {
    var video: Video?
    var expanded: Bool
  }

  func collapsedSize(s: GeometryProxy) -> CGSize {
    return CGSize(
      width: s.size.width * 0.2,
      height: s.size.width * 0.2 * (1 / (state.video?.Media?.first?.aspectRatio?.value ?? (16 / 9)))
    )
  }

  var body: some View {
    GeometryReader { s in
      if let video = state.video {
        VideoDetail(video: video, pip: $pip)
          .onChange(of: pip, perform: {
            self.state.expanded = $0
          })
          .allowsHitTesting(state.expanded)
          .cornerRadius(10)
          .shadow(radius: 10)
          .overlay(
            HStack {
              Button(action: {
                state.expanded.toggle()
              }, label: {
                Image(systemName: "chevron.up")
                  .foregroundColor(.white)
                  .rotationEffect(state.expanded ? Angle.degrees(180) : .zero)
                  .font(.title)
                  .padding(10)
              })
                .buttonStyle(PlainButtonStyle())

              Button(action: {
                withAnimation {
                state = ViewState(video: nil, expanded: false)
                }
              }, label: {
                Image(systemName: "xmark")
                  .foregroundColor(.white)
                  .font(.title)
                  .padding(10)
              })
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color.black.opacity(0.6)),

            alignment: Alignment(horizontal: .center, vertical: .top)
          )
          .frame(
            width: state.expanded ? s.size.width : collapsedSize(s: s).width,
            height: state.expanded ? s.size.height - 50 : collapsedSize(s: s).height
          )
          .offset(
            x: state.expanded ? 0 : s.size.width - collapsedSize(s: s).width - 10,
            y: state.expanded ? 50 : s.size.height - collapsedSize(s: s).height - 10
          )
          .animation(.easeInOut(duration: 0.6), value: state)
      }
    }
  }
}
