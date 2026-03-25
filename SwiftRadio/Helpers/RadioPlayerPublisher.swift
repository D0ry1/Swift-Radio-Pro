//
//  RadioPlayerPublisher.swift
//  SwiftRadio
//

import Foundation
@preconcurrency import Combine
import FRadioPlayer

final class RadioPlayerPublisher: @unchecked Sendable {

    static let shared = RadioPlayerPublisher()

    let playerState = PassthroughSubject<FRadioPlayer.State, Never>()
    let playbackState = PassthroughSubject<FRadioPlayer.PlaybackState, Never>()
    let metadata = PassthroughSubject<FRadioPlayer.Metadata?, Never>()
    let artworkURL = PassthroughSubject<URL?, Never>()

    private init() {
        FRadioPlayer.shared.addObserver(self)
    }
}

extension RadioPlayerPublisher: FRadioPlayerObserver {

    nonisolated func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayer.State) {
        playerState.send(state)
    }

    nonisolated func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlayer.PlaybackState) {
        playbackState.send(state)
    }

    nonisolated func radioPlayer(_ player: FRadioPlayer, metadataDidChange metadata: FRadioPlayer.Metadata?) {
        self.metadata.send(metadata)
    }

    nonisolated func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        self.artworkURL.send(artworkURL)
    }
}
