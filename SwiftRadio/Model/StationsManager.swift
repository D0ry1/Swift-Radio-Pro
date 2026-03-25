//
//  StationsManager.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2022-11-02.
//  Copyright © 2022 matthewfecher.com. All rights reserved.
//

import UIKit
import ActivityKit
import Combine
import FRadioPlayer
import MediaPlayer

@Observable
@MainActor
final class StationsManager {

    static let shared = StationsManager()

    private(set) var stations: [RadioStation] = []

    private(set) var currentStation: RadioStation? {
        didSet {
            resetArtwork(with: currentStation)
            if currentStation != nil {
                startLiveActivity()
            } else {
                endLiveActivity()
            }
        }
    }

    var searchedStations: [RadioStation] = []

    private let player = FRadioPlayer.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        let pub = RadioPlayerPublisher.shared

        pub.metadata
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.resetArtwork(with: self?.currentStation)
                self?.updateLiveActivity()
            }
            .store(in: &cancellables)

        pub.artworkURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in self?.handleArtworkChange(url) }
            .store(in: &cancellables)

        pub.playbackState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updatePlaybackState() }
            .store(in: &cancellables)
    }

    func fetch() async throws -> [RadioStation] {
        let newStations = try await DataManager.getStations()

        guard stations != newStations else {
            return stations
        }

        stations = newStations

        // Reset everything if the new stations list doesn't have the current station
        if let currentStation = currentStation, !stations.contains(currentStation) {
            reset()
        }

        return stations
    }

    func set(station: RadioStation?) {
        guard let station = station else {
            reset()
            return
        }

        currentStation = station
        player.radioURL = URL(string: station.streamURL)
    }

    func setNext() {
        guard let index = getIndex(of: currentStation) else { return }
        let station = (index + 1 == stations.count) ? stations[0] : stations[index + 1]
        currentStation = station
        player.radioURL = URL(string: station.streamURL)
    }

    func setPrevious() {
        guard let index = getIndex(of: currentStation), let station = (index == 0) ? stations.last : stations[index - 1] else { return }
        currentStation = station
        player.radioURL = URL(string: station.streamURL)
    }

    func updateSearch(with filter: String) {
        searchedStations.removeAll()
        searchedStations = stations.filter { $0.name.localizedCaseInsensitiveContains(filter) }
    }

    private func reset() {
        currentStation = nil
        player.radioURL = nil
    }

    private func getIndex(of station: RadioStation?) -> Int? {
        guard let station = station, let index = stations.firstIndex(of: station) else { return nil }
        return index
    }
}

// MARK: - MPNowPlayingInfoCenter (Lock screen)

extension StationsManager {

    private func resetArtwork(with station: RadioStation?) {

        guard let station = station else {
            updateLockScreen(with: nil)
            return
        }

        Task {
            let image = await station.getImage()
            updateLockScreen(with: image)
        }
    }

    private func handleArtworkChange(_ artworkURL: URL?) {
        guard let artworkURL = artworkURL else {
            resetArtwork(with: currentStation)
            return
        }

        Task {
            let image = await UIImage.image(from: artworkURL)
            guard let image = image else {
                resetArtwork(with: currentStation)
                return
            }

            updateLockScreen(with: image)
        }
    }

    private func updateLockScreen(with artworkImage: UIImage?) {

        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()

        if let image = artworkImage {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { size -> UIImage in
                return image
            })
        }

        if let artistName = currentStation?.artistName {
            nowPlayingInfo[MPMediaItemPropertyArtist] = artistName
        }

        if let trackName = currentStation?.trackName {
            nowPlayingInfo[MPMediaItemPropertyTitle] = trackName
        }

        // Set playback rate (1.0 = playing, 0.0 = paused) - controls play/pause button icon
        let isPlaying = player.isPlaying
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        let isOnDemand = player.isSeekable
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = !isOnDemand
        if isOnDemand {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.itemDuration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.itemCurrentTime
        }

        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .stopped
    }

    private func updatePlaybackState() {
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        let isPlaying = player.isPlaying
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .stopped

        updateLiveActivity()
    }
}

// MARK: - Live Activity

extension StationsManager {

    private var liveActivityState: NowPlayingAttributes.ContentState? {
        guard let station = currentStation else { return nil }
        return NowPlayingAttributes.ContentState(
            trackName: station.trackName,
            artistName: station.artistName,
            stationName: station.name,
            isPlaying: player.isPlaying
        )
    }

    func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled,
              let state = liveActivityState else { return }

        // End any existing activity first
        endLiveActivity()

        let attributes = NowPlayingAttributes()
        let content = ActivityContent(state: state, staleDate: nil)

        do {
            _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
        } catch {
            if Config.debugLog { print("Live Activity start failed: \(error)") }
        }
    }

    func updateLiveActivity() {
        guard let state = liveActivityState else {
            endLiveActivity()
            return
        }

        let content = ActivityContent(state: state, staleDate: nil)

        Task {
            for activity in Activity<NowPlayingAttributes>.activities {
                await activity.update(content)
            }
        }
    }

    func endLiveActivity() {
        Task {
            for activity in Activity<NowPlayingAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
