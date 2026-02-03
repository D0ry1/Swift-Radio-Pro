//
//  StationsManager.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2022-11-02.
//  Copyright © 2022 matthewfecher.com. All rights reserved.
//

import UIKit
import FRadioPlayer
import MediaPlayer

@MainActor
protocol StationsManagerObserver: AnyObject {
    func stationsManager(_ manager: StationsManager, stationsDidUpdate stations: [RadioStation])
    func stationsManager(_ manager: StationsManager, stationDidChange station: RadioStation?)
}

extension StationsManagerObserver {
    func stationsManager(_ manager: StationsManager, stationsDidUpdate stations: [RadioStation]) {}
}

@MainActor
final class StationsManager {

    static let shared = StationsManager()

    private(set) var stations: [RadioStation] = [] {
        didSet {
            notifyObservers { observer in
                observer.stationsManager(self, stationsDidUpdate: stations)
            }
        }
    }

    private(set) var currentStation: RadioStation? {
        didSet {
            notifyObservers { observer in
                observer.stationsManager(self, stationDidChange: currentStation)
            }

            resetArtwork(with: currentStation)
        }
    }

    var searchedStations: [RadioStation] = []

    private var observations = [ObjectIdentifier : Observation]()
    private let player = FRadioPlayer.shared

    private init() {
        self.player.addObserver(self)
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

// MARK: - StationsManager Observation

extension StationsManager {

    private struct Observation {
        weak var observer: StationsManagerObserver?
    }

    func addObserver(_ observer: StationsManagerObserver) {
        let id = ObjectIdentifier(observer)
        observations[id] = Observation(observer: observer)
    }

    func removeObserver(_ observer: StationsManagerObserver) {
        let id = ObjectIdentifier(observer)
        observations.removeValue(forKey: id)
    }

    private func notifyObservers(with action: (_ observer: StationsManagerObserver) -> Void) {
        for (id, observation) in observations {
            guard let observer = observation.observer else {
                observations.removeValue(forKey: id)
                continue
            }

            action(observer)
        }
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
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true

        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .stopped
    }
}

// MARK: - FRadioPlayerObserver

extension StationsManager: FRadioPlayerObserver {

    nonisolated func radioPlayer(_ player: FRadioPlayer, metadataDidChange metadata: FRadioPlayer.Metadata?) {
        Task { @MainActor in
            resetArtwork(with: currentStation)
        }
    }

    nonisolated func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        Task { @MainActor in
            guard let artworkURL = artworkURL else {
                resetArtwork(with: currentStation)
                return
            }

            let image = await UIImage.image(from: artworkURL)
            guard let image = image else {
                resetArtwork(with: currentStation)
                return
            }

            updateLockScreen(with: image)
        }
    }

    nonisolated func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlayer.PlaybackState) {
        Task { @MainActor in
            updatePlaybackState()
        }
    }

    private func updatePlaybackState() {
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        let isPlaying = player.isPlaying
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .stopped
    }
}
