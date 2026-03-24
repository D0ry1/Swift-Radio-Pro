import Testing
import Foundation
@testable import SwiftRadio

@Suite("Config Tests")
struct ConfigTests {

    @Test("onDemandURL is valid HTTPS with correct host")
    func onDemandURLValid() throws {
        let url = try #require(URL(string: Config.onDemandURL))
        #expect(url.scheme == "https")
        #expect(url.host == "thegatesradio.co.uk")
    }

    @Test("onDemandBaseURL is valid HTTPS with no trailing slash")
    func onDemandBaseURLValid() throws {
        let url = try #require(URL(string: Config.onDemandBaseURL))
        #expect(url.scheme == "https")
        #expect(!Config.onDemandBaseURL.hasSuffix("/"))
    }

    @Test("stationsURL is a valid URL")
    func stationsURLValid() {
        let url = URL(string: Config.stationsURL)
        #expect(url != nil)
    }
}
