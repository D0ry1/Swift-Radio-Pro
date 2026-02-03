//
//  CarPlaySceneDelegate.swift
//  SwiftRadio
//
//  Created by Claude on 2026-02-03.
//  Copyright © 2026 matthewfecher.com. All rights reserved.
//

import CarPlay
import UIKit
import MediaPlayer
import FRadioPlayer

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    var interfaceController: CPInterfaceController?
    private var stationListTemplate: CPListTemplate?
    private let player = FRadioPlayer.shared

    // MARK: - CPTemplateApplicationSceneDelegate

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        configureNowPlayingTemplate()
        player.addObserver(self)
        Task { @MainActor in
            StationsManager.shared.addObserver(self)
            await configureRootTemplate()
        }
    }

    private func configureNowPlayingTemplate() {
        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        nowPlayingTemplate.isUpNextButtonEnabled = false
        nowPlayingTemplate.isAlbumArtistButtonEnabled = false
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
        player.removeObserver(self)
        Task { @MainActor in
            StationsManager.shared.removeObserver(self)
        }
    }

    // MARK: - Template Configuration

    @MainActor
    private func configureRootTemplate() async {
        // Fetch stations if needed
        do {
            _ = try await StationsManager.shared.fetch()
        } catch {
            if Config.debugLog {
                print("CarPlay: Failed to fetch stations: \(error.localizedDescription)")
            }
        }

        let listTemplate = buildStationListTemplate()
        stationListTemplate = listTemplate

        interfaceController?.setRootTemplate(listTemplate, animated: true, completion: nil)
    }

    @MainActor
    private func buildStationListTemplate() -> CPListTemplate {
        let stations = StationsManager.shared.stations
        let currentStation = StationsManager.shared.currentStation

        let items: [CPListItem] = stations.map { station in
            let item = CPListItem(text: station.name, detailText: station.desc)
            item.isPlaying = (station == currentStation)
            item.accessoryType = .disclosureIndicator

            // Load artwork asynchronously
            Task {
                let image = await station.getImage()
                item.setImage(image)
            }

            item.handler = { [weak self] _, completion in
                self?.handleStationSelection(station)
                completion()
            }

            return item
        }

        let section = CPListSection(items: items)
        let listTemplate = CPListTemplate(title: "Stations", sections: [section])

        if let tabImage = UIImage(named: "carPlayTab") {
            listTemplate.tabImage = tabImage
        }

        return listTemplate
    }

    @MainActor
    private func handleStationSelection(_ station: RadioStation) {
        StationsManager.shared.set(station: station)

        // Set up Now Playing info immediately with station details
        Task {
            await updateNowPlayingInfo(for: station)
            showNowPlaying()
        }
    }

    @MainActor
    private func updateNowPlayingInfo(for station: RadioStation) async {
        var nowPlayingInfo = [String: Any]()

        // Set station name and description
        nowPlayingInfo[MPMediaItemPropertyTitle] = station.trackName
        nowPlayingInfo[MPMediaItemPropertyArtist] = station.artistName
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
        // Set to 1.0 since auto-play is enabled - will be updated by FRadioPlayerObserver
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0

        // Load and set artwork
        let image = await station.getImage()
        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        MPNowPlayingInfoCenter.default().playbackState = .playing
    }

    private func updatePlaybackRate() {
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        let isPlaying = player.isPlaying
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .stopped
    }

    private func showNowPlaying() {
        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        interfaceController?.pushTemplate(nowPlayingTemplate, animated: true, completion: nil)
    }

    @MainActor
    private func updateStationList() {
        guard let listTemplate = stationListTemplate else { return }

        let stations = StationsManager.shared.stations
        let currentStation = StationsManager.shared.currentStation

        let items: [CPListItem] = stations.map { station in
            let item = CPListItem(text: station.name, detailText: station.desc)
            item.isPlaying = (station == currentStation)
            item.accessoryType = .disclosureIndicator

            // Load artwork asynchronously
            Task {
                let image = await station.getImage()
                item.setImage(image)
            }

            item.handler = { [weak self] _, completion in
                self?.handleStationSelection(station)
                completion()
            }

            return item
        }

        let section = CPListSection(items: items)
        listTemplate.updateSections([section])
    }
}

// MARK: - StationsManagerObserver

extension CarPlaySceneDelegate: StationsManagerObserver {

    func stationsManager(_ manager: StationsManager, stationsDidUpdate stations: [RadioStation]) {
        updateStationList()
    }

    func stationsManager(_ manager: StationsManager, stationDidChange station: RadioStation?) {
        updateStationList()
    }
}

// MARK: - FRadioPlayerObserver

extension CarPlaySceneDelegate: FRadioPlayerObserver {

    nonisolated func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlayer.PlaybackState) {
        Task { @MainActor in
            updatePlaybackRate()
        }
    }
}
