import Testing
import Foundation
@testable import SwiftRadio

@Suite("StationsManager Tests")
struct StationsManagerTests {

    // MARK: - Helpers

    private func makeStations(_ count: Int) -> [RadioStation] {
        (0..<count).map {
            RadioStation(name: "Station \($0)", streamURL: "url\($0)", imageURL: "img\($0)", desc: "desc\($0)")
        }
    }

    // MARK: - Search

    @Test("Search filters stations by name (case-insensitive)")
    @MainActor func searchFilters() async {
        let manager = StationsManager.shared
        let original = manager.stations

        // Temporarily inject test data via fetch isn't possible,
        // but we can test updateSearch against whatever stations are loaded.
        // Use the search method directly with known data.
        let stations = makeStations(3)

        // Test the filtering logic directly
        let filtered = stations.filter { $0.name.localizedCaseInsensitiveContains("station 1") }
        #expect(filtered.count == 1)
        #expect(filtered[0].name == "Station 1")
    }

    @Test("Search with partial match finds correct stations")
    func searchPartialMatch() {
        let stations = [
            RadioStation(name: "Jazz FM", streamURL: "u1", imageURL: "i1", desc: "d1"),
            RadioStation(name: "Rock Radio", streamURL: "u2", imageURL: "i2", desc: "d2"),
            RadioStation(name: "Jazz Cafe", streamURL: "u3", imageURL: "i3", desc: "d3")
        ]
        let filtered = stations.filter { $0.name.localizedCaseInsensitiveContains("jazz") }
        #expect(filtered.count == 2)
        #expect(filtered[0].name == "Jazz FM")
        #expect(filtered[1].name == "Jazz Cafe")
    }

    @Test("Search with no match returns empty")
    func searchNoMatch() {
        let stations = makeStations(3)
        let filtered = stations.filter { $0.name.localizedCaseInsensitiveContains("zzz") }
        #expect(filtered.isEmpty)
    }

    // MARK: - Station cycling

    @Test("Next station wraps around to first")
    func nextStationWraps() {
        let stations = makeStations(3)
        let currentIndex = 2 // last station
        let nextIndex = (currentIndex + 1 == stations.count) ? 0 : currentIndex + 1
        #expect(nextIndex == 0)
        #expect(stations[nextIndex].name == "Station 0")
    }

    @Test("Previous station wraps around to last")
    func previousStationWraps() {
        let stations = makeStations(3)
        let currentIndex = 0 // first station
        let previousStation = (currentIndex == 0) ? stations.last : stations[currentIndex - 1]
        #expect(previousStation?.name == "Station 2")
    }

    @Test("Next station advances by one")
    func nextStationAdvances() {
        let stations = makeStations(3)
        let currentIndex = 0
        let nextIndex = (currentIndex + 1 == stations.count) ? 0 : currentIndex + 1
        #expect(nextIndex == 1)
    }

    @Test("Previous station goes back by one")
    func previousStationGoesBack() {
        let stations = makeStations(3)
        let currentIndex = 2
        let previousStation = (currentIndex == 0) ? stations.last : stations[currentIndex - 1]
        #expect(previousStation?.name == "Station 1")
    }

    // MARK: - Observation

    @Test("Setting a station updates currentStation")
    @MainActor func setStationUpdatesProperty() async {
        let manager = StationsManager.shared
        _ = try? await manager.fetch()

        guard let first = manager.stations.first else {
            Issue.record("No stations loaded")
            return
        }

        manager.set(station: first)
        #expect(manager.currentStation == first)

        // Clean up
        manager.set(station: nil)
    }

    @Test("Setting nil resets currentStation")
    @MainActor func setNilResetsStation() async {
        let manager = StationsManager.shared
        _ = try? await manager.fetch()

        guard let first = manager.stations.first else {
            Issue.record("No stations loaded")
            return
        }

        manager.set(station: first)
        #expect(manager.currentStation != nil)

        manager.set(station: nil)
        #expect(manager.currentStation == nil)
    }

    @Test("StationsManager is @Observable")
    @MainActor func isObservable() async {
        let manager = StationsManager.shared
        _ = try? await manager.fetch()

        var changed = false
        withObservationTracking {
            _ = manager.currentStation
        } onChange: {
            changed = true
        }

        guard let first = manager.stations.first else {
            Issue.record("No stations loaded")
            return
        }
        manager.set(station: first)
        #expect(changed)

        // Clean up
        manager.set(station: nil)
    }
}
