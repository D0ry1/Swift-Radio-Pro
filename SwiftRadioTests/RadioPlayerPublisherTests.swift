import Testing
import Combine
import Foundation
@testable import SwiftRadio

@Suite("RadioPlayerPublisher Tests")
struct RadioPlayerPublisherTests {

    @Test("Shared instance is a singleton")
    func sharedIsSingleton() {
        let a = RadioPlayerPublisher.shared
        let b = RadioPlayerPublisher.shared
        #expect(a === b)
    }

    @Test("PlayerState publisher can be subscribed to without crash")
    func playerStateSubscribable() {
        var cancellable: AnyCancellable?
        cancellable = RadioPlayerPublisher.shared.playerState
            .sink { _ in }
        #expect(cancellable != nil)
        cancellable?.cancel()
    }

    @Test("PlaybackState publisher can be subscribed to without crash")
    func playbackStateSubscribable() {
        var cancellable: AnyCancellable?
        cancellable = RadioPlayerPublisher.shared.playbackState
            .sink { _ in }
        #expect(cancellable != nil)
        cancellable?.cancel()
    }

    @Test("Metadata publisher can be subscribed to without crash")
    func metadataSubscribable() {
        var cancellable: AnyCancellable?
        cancellable = RadioPlayerPublisher.shared.metadata
            .sink { _ in }
        #expect(cancellable != nil)
        cancellable?.cancel()
    }

    @Test("ArtworkURL publisher can be subscribed to without crash")
    func artworkURLSubscribable() {
        var cancellable: AnyCancellable?
        cancellable = RadioPlayerPublisher.shared.artworkURL
            .sink { _ in }
        #expect(cancellable != nil)
        cancellable?.cancel()
    }
}
