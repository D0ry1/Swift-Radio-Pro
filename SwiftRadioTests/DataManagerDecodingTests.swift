import Testing
import Foundation
@testable import SwiftRadio

@Suite("DataManager Decoding Tests")
struct DataManagerDecodingTests {

    private let decoder = JSONDecoder()

    // MARK: - Station JSON Decoding

    @Test("Valid station JSON decodes successfully")
    func validStationJSON() throws {
        let json = """
        {
            "station": [
                {
                    "name": "Test FM",
                    "streamURL": "https://stream.example.com/live",
                    "imageURL": "https://example.com/logo.png",
                    "desc": "A test station",
                    "longDesc": ""
                }
            ]
        }
        """.data(using: .utf8)!

        let dict = try decoder.decode([String: [RadioStation]].self, from: json)
        let stations = dict["station"]
        #expect(stations != nil)
        #expect(stations?.count == 1)
        #expect(stations?[0].name == "Test FM")
    }

    @Test("Missing 'station' key results in nil lookup")
    func missingStationKey() throws {
        let json = """
        {
            "other": []
        }
        """.data(using: .utf8)!

        let dict = try decoder.decode([String: [RadioStation]].self, from: json)
        #expect(dict["station"] == nil)
    }

    @Test("Empty station array decodes to empty list")
    func emptyStationArray() throws {
        let json = """
        {
            "station": []
        }
        """.data(using: .utf8)!

        let dict = try decoder.decode([String: [RadioStation]].self, from: json)
        let stations = try #require(dict["station"])
        #expect(stations.isEmpty)
    }

    @Test("Invalid JSON throws DecodingError")
    func invalidJSON() {
        let json = "not valid json".data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try decoder.decode([String: [RadioStation]].self, from: json)
        }
    }

    // MARK: - On-Demand Episode Decoding

    @Test("Valid episode array with mixed nulls decodes")
    func validEpisodeArray() throws {
        let json = """
        [
            {
                "track_id": "1",
                "download_url": "/a.mp3",
                "media": { "id": "m1", "art": "https://example.com/art.jpg", "title": "Show A", "text": "Desc A" }
            },
            {
                "track_id": "2",
                "download_url": "/b.mp3",
                "media": { "id": null, "art": null, "title": null, "text": null }
            }
        ]
        """.data(using: .utf8)!

        let episodes = try decoder.decode([OnDemandEpisode].self, from: json)
        #expect(episodes.count == 2)
        #expect(episodes[0].media.title == "Show A")
        #expect(episodes[1].media.title == nil)
    }

    @Test("Empty episode array decodes to empty list")
    func emptyEpisodeArray() throws {
        let json = "[]".data(using: .utf8)!
        let episodes = try decoder.decode([OnDemandEpisode].self, from: json)
        #expect(episodes.isEmpty)
    }

    // MARK: - DataError

    @Test("DataError cases are distinct")
    func dataErrorCasesDistinct() {
        let errors: [DataError] = [
            .urlNotValid, .dataNotValid, .dataNotFound, .fileNotFound, .httpResponseNotValid
        ]
        for (i, a) in errors.enumerated() {
            for (j, b) in errors.enumerated() where i != j {
                #expect(a.localizedDescription != b.localizedDescription || "\(a)" != "\(b)")
            }
        }
    }
}
