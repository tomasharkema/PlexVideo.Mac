//
//  StreamHelpers.swift
//
//
//  Created by Tomas Harkema on 25/10/2023.
//

import Foundation
import PlexCore
import PlexShared

let bandwidthFormatter: MeasurementFormatter = {
  let formatter = MeasurementFormatter()
  formatter.numberFormatter.maximumFractionDigits = 0
  formatter.numberFormatter.roundingMode = .up
  return formatter
}()

extension SessionVideo {
  var duration: Double? {
    (video.video.media?.first?.duration.value).map { $0 / 1000 }
  }

  var viewOffset: Double {
    session.viewOffset / 1000
  }

  var playerState: String? {
    session.player?.value?.state
  }

  public var bandwidthMeasurement: Measurement<UnitInformationStorage>? {
    (session.session?.value?.bandwidth).map {
      Measurement(value: $0, unit: .kilobits)
    }
  }

  public var bandwidthMbps: String? {
    guard let value = bandwidthMeasurement?.converted(to: .megabits) else {
      return nil
    }
    return "\(bandwidthFormatter.string(from: value))ps"
  }
}

public extension SessionStatus {
  var selectedMedia: Media? {
    media?.selected?.value
  }

  var streams: [PlexShared.Stream] {
    let media: Media? = selectedMedia
    let part = media?.part?.selected?.value
    let streams = part?.stream
    return streams?.compactMap(\.value) ?? []
  }

  var videoStream: PlexShared.Stream? {
    streams.selected {
      $0.streamType == .video
    }
  }

  var audioStream: PlexShared.Stream? {
    streams.selected {
      $0.streamType == .audio
    }
  }

  var subtitleStream: PlexShared.Stream? {
    streams.selected {
      $0.streamType == .subtitles
    }
  }

  var videoSourceString: String {
    let stream = videoStream
    let displayTitle = stream?.displayTitle ?? ""

//    let bitrate = stream?.bitrateMeasurement?.converted(to: .megabits)
//    let bitrateString = bitrate
//      .map { bandwidthFormatter.string(from: $0) }
//      .map { "\($0)ps"}

    let components = [
      displayTitle,
//      bitrateString
      //      size,
      //      codec
    ].compactMap { $0 }

    return components.joined(separator: " ")
  }

  var videoString: String {
    let selectedMedia = selectedMedia
    let stream = videoStream

    guard stream?.decision == "transcode" else {
      return "Direct"
    }

    let codecString = stream?.codec.map {
      "\($0.localizedUppercase) - Transcoding"
    } ?? "Direct"

    let bitrate = stream?.bitrateMeasurement?.converted(to: .megabits)
    let bitrateString = bitrate
      .map { bandwidthFormatter.string(from: $0) }
      .map { "\($0)ps" }

    let components = [
      selectedMedia?.videoResolution,
      codecString,
      bitrateString,
      hardwareTranscodingString,
    ].compactMap { $0 }

    return components.joined(separator: " ")
  }

  var audioSourceString: String {
    let stream = audioStream
    let displayTitle = stream?.displayTitle ?? ""

//    let bitrate = stream?.bitrateMeasurement?.converted(to: .megabits)
//    let bitrateString = bitrate
//      .map { bandwidthFormatter.string(from: $0) }
//      .map { "\($0)ps"}

    let components = [
      displayTitle,
//      bitrateString
      //      size,
      //      codec
    ].compactMap { $0 }

    return components.joined(separator: " ")
  }

  var audioString: String {
    let stream = audioStream

    guard stream?.decision == "transcode" else {
      return "Direct"
    }

    let codecString = stream?.codec.map {
      "\($0.localizedUppercase) - Transcoding"
    }

    let bitrate = stream?.bitrateMeasurement?.converted(to: .megabits)
    let bitrateString = bitrate
      .map { bandwidthFormatter.string(from: $0) }
      .map { "\($0)ps" }

    let components = [
      codecString,
      bitrateString,
    ].compactMap { $0 }

    return components.joined(separator: " ")
  }

  var subtitleString: String? {
    let stream = subtitleStream
    return stream?.displayTitle
  }

  var hardwareTranscodingString: String? {
    let components = [
      transcodeSession?.value?.transcodeHwDecoding,
      transcodeSession?.value?.transcodeHwEncoding,
    ].compactMap { $0 }
    print(transcodeSession?.error)
    guard !components.isEmpty else {
      return nil
    }

    return "(hw: \(components.joined(separator: " ")))"
  }
}
