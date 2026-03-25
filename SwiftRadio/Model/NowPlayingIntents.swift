//
//  NowPlayingIntents.swift
//  SwiftRadio
//

import AppIntents
#if MAIN_APP
import FRadioPlayer
#endif

struct TogglePlaybackIntent: LiveActivityIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Toggle Playback"
    static var description: IntentDescription { "Play or pause the current station" }

    @MainActor
    func perform() async throws -> some IntentResult {
        #if MAIN_APP
        FRadioPlayer.shared.togglePlaying()
        StationsManager.shared.updateLiveActivity()
        #endif
        return .result()
    }
}

struct NextStationIntent: LiveActivityIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Next Station"
    static var description: IntentDescription { "Skip to the next station" }

    @MainActor
    func perform() async throws -> some IntentResult {
        #if MAIN_APP
        StationsManager.shared.setNext()
        #endif
        return .result()
    }
}

struct PreviousStationIntent: LiveActivityIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Previous Station"
    static var description: IntentDescription { "Go to the previous station" }

    @MainActor
    func perform() async throws -> some IntentResult {
        #if MAIN_APP
        StationsManager.shared.setPrevious()
        #endif
        return .result()
    }
}
