//
//  NowPlayingLiveActivity.swift
//  NowPlayingWidget
//

import SwiftUI
import WidgetKit
import ActivityKit
import AppIntents

struct NowPlayingLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NowPlayingAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Button(intent: PreviousStationIntent()) {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.trackName)
                            .font(.headline)
                            .lineLimit(1)
                        Text(context.state.artistName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Button(intent: NextStationIntent()) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.stationName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(intent: TogglePlaybackIntent()) {
                            Image(systemName: context.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.cyan)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } compactLeading: {
                Button(intent: TogglePlaybackIntent()) {
                    Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                        .foregroundStyle(.cyan)
                }
                .buttonStyle(.plain)
            } compactTrailing: {
                Text(context.state.trackName)
                    .font(.caption)
                    .lineLimit(1)
                    .frame(maxWidth: 80)
            } minimal: {
                Image(systemName: context.state.isPlaying ? "radio.fill" : "radio")
                    .foregroundStyle(.cyan)
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<NowPlayingAttributes>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "radio.fill")
                .font(.largeTitle)
                .foregroundStyle(.cyan)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.trackName)
                    .font(.headline)
                    .lineLimit(1)
                Text(context.state.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(context.state.stationName)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 16) {
                Button(intent: PreviousStationIntent()) {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                        .foregroundStyle(.cyan)
                }
                .buttonStyle(.plain)

                Button(intent: TogglePlaybackIntent()) {
                    Image(systemName: context.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .foregroundStyle(.cyan)
                }
                .buttonStyle(.plain)

                Button(intent: NextStationIntent()) {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .foregroundStyle(.cyan)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}
