//
//  NowPlayingAttributes.swift
//  SwiftRadio
//

import ActivityKit
import Foundation

struct NowPlayingAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var trackName: String
        var artistName: String
        var stationName: String
        var isPlaying: Bool
    }
}
