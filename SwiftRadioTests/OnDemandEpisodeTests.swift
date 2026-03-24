import Testing
import Foundation
@testable import SwiftRadio

@Suite("OnDemandEpisode Tests")
struct OnDemandEpisodeTests {

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // MARK: - JSON Decoding

    @Test("Decodes complete JSON object")
    func decodesCompleteObject() throws {
        let json = """
        {
            "track_id": "42",
            "download_url": "/media/show.mp3",
            "media": {
                "id": "m1",
                "art": "https://example.com/art.jpg",
                "title": "Morning Show",
                "text": "A great episode"
            }
        }
        """.data(using: .utf8)!

        let episode = try decoder.decode(OnDemandEpisode.self, from: json)
        #expect(episode.trackId == "42")
        #expect(episode.downloadUrl == "/media/show.mp3")
        #expect(episode.media.id == "m1")
        #expect(episode.media.art == "https://example.com/art.jpg")
        #expect(episode.media.title == "Morning Show")
        #expect(episode.media.text == "A great episode")
    }

    @Test("Decodes when optional media fields are null")
    func decodesNullOptionalMediaFields() throws {
        let json = """
        {
            "track_id": "1",
            "download_url": "/file.mp3",
            "media": {
                "id": null,
                "art": null,
                "title": null,
                "text": null
            }
        }
        """.data(using: .utf8)!

        let episode = try decoder.decode(OnDemandEpisode.self, from: json)
        #expect(episode.media.id == nil)
        #expect(episode.media.art == nil)
        #expect(episode.media.title == nil)
        #expect(episode.media.text == nil)
    }

    @Test("Fails to decode when required field is missing")
    func failsOnMissingRequiredField() {
        let json = """
        {
            "track_id": "1",
            "media": { "id": "m1" }
        }
        """.data(using: .utf8)!

        #expect(throws: DecodingError.self) {
            try decoder.decode(OnDemandEpisode.self, from: json)
        }
    }

    @Test("Decodes array of episodes")
    func decodesArray() throws {
        let json = """
        [
            {
                "track_id": "1",
                "download_url": "/a.mp3",
                "media": { "id": "m1", "art": null, "title": "Ep1", "text": null }
            },
            {
                "track_id": "2",
                "download_url": "/b.mp3",
                "media": { "id": "m2", "art": "https://example.com/art.jpg", "title": "Ep2", "text": "desc" }
            }
        ]
        """.data(using: .utf8)!

        let episodes = try decoder.decode([OnDemandEpisode].self, from: json)
        #expect(episodes.count == 2)
        #expect(episodes[0].trackId == "1")
        #expect(episodes[1].trackId == "2")
    }

    // MARK: - Computed Properties

    @Test("fullDownloadURL prepends base URL")
    func fullDownloadURL() throws {
        let json = """
        {
            "track_id": "1",
            "download_url": "/media/show.mp3",
            "media": { "id": null, "art": null, "title": null, "text": null }
        }
        """.data(using: .utf8)!

        let episode = try decoder.decode(OnDemandEpisode.self, from: json)
        #expect(episode.fullDownloadURL == Config.onDemandBaseURL + "/media/show.mp3")
    }

    @Test("artworkURL returns media.art when present")
    func artworkURLWithArt() throws {
        let json = """
        {
            "track_id": "1",
            "download_url": "/x.mp3",
            "media": { "id": null, "art": "https://example.com/pic.jpg", "title": null, "text": null }
        }
        """.data(using: .utf8)!

        let episode = try decoder.decode(OnDemandEpisode.self, from: json)
        #expect(episode.artworkURL == "https://example.com/pic.jpg")
    }

    @Test("artworkURL returns empty string when media.art is nil")
    func artworkURLNilFallback() throws {
        let json = """
        {
            "track_id": "1",
            "download_url": "/x.mp3",
            "media": { "id": null, "art": null, "title": null, "text": null }
        }
        """.data(using: .utf8)!

        let episode = try decoder.decode(OnDemandEpisode.self, from: json)
        #expect(episode.artworkURL == "")
    }

    // MARK: - toRadioStation

    @Test("toRadioStation maps fields correctly")
    func toRadioStationMapping() throws {
        let json = """
        {
            "track_id": "99",
            "download_url": "/show.mp3",
            "media": { "id": "m1", "art": "https://example.com/art.jpg", "title": "My Show", "text": "Show description" }
        }
        """.data(using: .utf8)!

        let episode = try decoder.decode(OnDemandEpisode.self, from: json)
        let station = episode.toRadioStation()
        #expect(station.name == "My Show")
        #expect(station.streamURL == episode.fullDownloadURL)
        #expect(station.imageURL == "https://example.com/art.jpg")
        #expect(station.desc == "Show description")
    }

    @Test("toRadioStation uses defaults when media fields are nil")
    func toRadioStationDefaults() throws {
        let json = """
        {
            "track_id": "1",
            "download_url": "/x.mp3",
            "media": { "id": null, "art": null, "title": null, "text": null }
        }
        """.data(using: .utf8)!

        let episode = try decoder.decode(OnDemandEpisode.self, from: json)
        let station = episode.toRadioStation()
        #expect(station.name == "Unknown")
        #expect(station.imageURL == "")
        #expect(station.desc == "")
    }

    // MARK: - Roundtrip

    @Test("Encode then decode produces equivalent episode")
    func encodingDecodingRoundtrip() throws {
        let json = """
        {
            "track_id": "7",
            "download_url": "/media/ep7.mp3",
            "media": { "id": "m7", "art": "https://example.com/7.jpg", "title": "Episode 7", "text": "Lucky number" }
        }
        """.data(using: .utf8)!

        let original = try decoder.decode(OnDemandEpisode.self, from: json)
        let encoded = try encoder.encode(original)
        let decoded = try decoder.decode(OnDemandEpisode.self, from: encoded)

        #expect(decoded.trackId == original.trackId)
        #expect(decoded.downloadUrl == original.downloadUrl)
        #expect(decoded.media.id == original.media.id)
        #expect(decoded.media.art == original.media.art)
        #expect(decoded.media.title == original.media.title)
        #expect(decoded.media.text == original.media.text)
    }
}
