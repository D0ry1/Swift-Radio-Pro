import Testing
import Foundation
@testable import SwiftRadio

@Suite("RadioStation Tests")
struct RadioStationTests {

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // MARK: - Initialisation

    @Test("Init with all parameters")
    func initWithAllParams() {
        let station = RadioStation(
            name: "Test FM",
            streamURL: "https://stream.example.com/live",
            imageURL: "https://example.com/logo.png",
            desc: "The best station",
            longDesc: "A longer description of the station"
        )
        #expect(station.name == "Test FM")
        #expect(station.streamURL == "https://stream.example.com/live")
        #expect(station.imageURL == "https://example.com/logo.png")
        #expect(station.desc == "The best station")
        #expect(station.longDesc == "A longer description of the station")
    }

    @Test("Init default longDesc is empty string")
    func initDefaultLongDesc() {
        let station = RadioStation(
            name: "Test FM",
            streamURL: "https://stream.example.com/live",
            imageURL: "logo.png",
            desc: "desc"
        )
        #expect(station.longDesc == "")
    }

    // MARK: - Equatable

    @Test("Equal stations are equal")
    func equalStations() {
        let a = RadioStation(name: "FM", streamURL: "url", imageURL: "img", desc: "d", longDesc: "l")
        let b = RadioStation(name: "FM", streamURL: "url", imageURL: "img", desc: "d", longDesc: "l")
        #expect(a == b)
    }

    @Test("Stations differ when any field differs",
          arguments: ["name", "streamURL", "imageURL", "desc", "longDesc"])
    func stationsNotEqual(field: String) {
        let base = RadioStation(name: "FM", streamURL: "url", imageURL: "img", desc: "d", longDesc: "l")
        var other = base
        switch field {
        case "name":      other.name = "OTHER"
        case "streamURL": other.streamURL = "OTHER"
        case "imageURL":  other.imageURL = "OTHER"
        case "desc":      other.desc = "OTHER"
        case "longDesc":  other.longDesc = "OTHER"
        default: break
        }
        #expect(base != other)
    }

    // MARK: - Codable

    @Test("Decodes from station dictionary format")
    func decodesFromStationDictionary() throws {
        let json = """
        {
            "station": [
                {
                    "name": "Station One",
                    "streamURL": "https://stream.example.com/one",
                    "imageURL": "https://example.com/one.png",
                    "desc": "First station",
                    "longDesc": "The very first station"
                }
            ]
        }
        """.data(using: .utf8)!

        let dict = try decoder.decode([String: [RadioStation]].self, from: json)
        let stations = try #require(dict["station"])
        #expect(stations.count == 1)
        #expect(stations[0].name == "Station One")
    }

    @Test("Encode and decode roundtrip preserves values")
    func codableRoundtrip() throws {
        let original = RadioStation(
            name: "Roundtrip FM",
            streamURL: "https://stream.example.com/rt",
            imageURL: "https://example.com/rt.png",
            desc: "Roundtrip desc",
            longDesc: "Longer roundtrip desc"
        )
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RadioStation.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - shoutout

    @Test("shoutout contains station name")
    func shoutoutContainsName() {
        let station = RadioStation(name: "Cool FM", streamURL: "url", imageURL: "img", desc: "d")
        #expect(station.shoutout.contains("Cool FM"))
    }
}
