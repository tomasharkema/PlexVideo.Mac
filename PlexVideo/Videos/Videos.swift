////
////  Videos.swift
////  PlexVideo
////
////  Created by Tomas Harkema on 27/05/2021.
////
//
//import Foundation
//import SwiftUI
//import PlexApi
//import PlexShared
//import PlexCore
//
//@MainActor
//struct Videos: View {
////  @State 
////  private var viewModel = VideosViewModel()
//
//  @Environment(VideosViewModel.self)
//  private var viewModel
//
//  var body: some View {
//    ZStack(alignment: .bottom) {
//      NavigationStack {
//        ZStack(alignment: .top) {
//          VideosGridScreen()
//          ConnectionOverlay()
//        }
//        //.overlay(ProgressView().opacity(viewModel.data.isLoading ? 1 : 0))
//      }
//      PlayerOverlay()
//    }
//    .task {
//      await viewModel.load(silently: false)
//    }
////    .onChange(of: viewModel.savedLastPlayed) {
////      // on startup, start the last saved playing video
////      if video == nil {
////        video = viewModel.savedLastPlayed
////      }
////    }
////    .onChange(of: video) {
////      if video == nil {
////        self.viewModel.resetLastPlayed()
////      }
////    }
//  }
//}
