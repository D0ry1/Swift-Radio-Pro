import Testing
import Foundation
@testable import SwiftRadio

@Suite("DataError Tests")
struct DataErrorTests {

    @Test("Each error case has a unique description",
          arguments: [DataError.urlNotValid, .dataNotValid, .dataNotFound, .fileNotFound, .httpResponseNotValid])
    func uniqueDescriptions(error: DataError) {
        let all: [DataError] = [.urlNotValid, .dataNotValid, .dataNotFound, .fileNotFound, .httpResponseNotValid]
        let others = all.filter { "\($0)" != "\(error)" }
        #expect(others.count == all.count - 1)
    }

    @Test("DataError conforms to Error")
    func conformsToError() {
        let error: Error = DataError.urlNotValid
        #expect(error is DataError)
    }

    @Test("DataError localizedDescription is not empty",
          arguments: [DataError.urlNotValid, .dataNotValid, .dataNotFound, .fileNotFound, .httpResponseNotValid])
    func nonEmptyDescription(error: DataError) {
        #expect(!error.localizedDescription.isEmpty)
    }
}
