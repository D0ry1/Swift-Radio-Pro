//
//  FRadioPlayer+Seek.swift
//  SwiftRadio
//

import AVFoundation
import FRadioPlayer

extension FRadioPlayer.State: @retroactive @unchecked Sendable {}
extension FRadioPlayer.PlaybackState: @retroactive @unchecked Sendable {}

extension FRadioPlayer {

    /// Access the underlying AVPlayer via Mirror reflection
    var avPlayer: AVPlayer? {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if child.label == "player" {
                return child.value as? AVPlayer
            }
        }
        return nil
    }

    /// The actual duration from the AVPlayerItem (FRadioPlayer's own duration property is never updated)
    var itemDuration: TimeInterval {
        guard let item = avPlayer?.currentItem else { return 0 }
        let duration = item.duration
        guard duration.isNumeric else { return 0 }
        return CMTimeGetSeconds(duration)
    }

    /// The actual current playback time
    var itemCurrentTime: TimeInterval {
        guard let player = avPlayer else { return 0 }
        let time = player.currentTime()
        guard time.isNumeric else { return 0 }
        return CMTimeGetSeconds(time)
    }

    /// Whether the current item is seekable (on-demand, not a live stream)
    var isSeekable: Bool {
        itemDuration > 0
    }

    /// Seek to a specific time in seconds
    func seek(to time: TimeInterval) {
        guard let player = avPlayer else { return }
        let duration = itemDuration
        guard duration > 0, time >= 0, time <= duration else { return }

        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
}
