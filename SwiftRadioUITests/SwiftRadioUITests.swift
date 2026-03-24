import XCTest

final class SwiftRadioUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Smoke Tests

    func testAppLaunchesAndShowsStationsList() {
        // The loader fetches stations then transitions to the stations screen.
        // Wait for the nav bar title "Swift Radio" to appear (up to 10s for network).
        let navBar = app.navigationBars["Swift Radio"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 10),
                       "Stations screen should appear after loading")
    }

    func testPreviousShowsButtonExists() {
        let navBar = app.navigationBars["Swift Radio"]
        guard navBar.waitForExistence(timeout: 10) else {
            XCTFail("Stations screen did not appear")
            return
        }

        let previousShowsButton = app.buttons["Previous Shows"]
        XCTAssertTrue(previousShowsButton.exists,
                       "Previous Shows button should be visible in the stations list")
    }

    func testPreviousShowsButtonNavigates() {
        let navBar = app.navigationBars["Swift Radio"]
        guard navBar.waitForExistence(timeout: 10) else {
            XCTFail("Stations screen did not appear")
            return
        }

        app.buttons["Previous Shows"].tap()

        let previousShowsNav = app.navigationBars["Previous Shows"]
        XCTAssertTrue(previousShowsNav.waitForExistence(timeout: 10),
                       "Should navigate to Previous Shows screen")
    }

    func testHamburgerMenuOpens() {
        let navBar = app.navigationBars["Swift Radio"]
        guard navBar.waitForExistence(timeout: 10) else {
            XCTFail("Stations screen did not appear")
            return
        }

        // The hamburger button is the left bar button item
        let menuButton = navBar.buttons.element(boundBy: 0)
        XCTAssertTrue(menuButton.exists, "Hamburger menu button should exist")
        menuButton.tap()

        // The pop-up menu should appear — look for common menu items
        let aboutButton = app.buttons["About"]
        let websiteButton = app.buttons["Website"]
        let menuAppeared = aboutButton.waitForExistence(timeout: 5)
                        || websiteButton.waitForExistence(timeout: 2)
        XCTAssertTrue(menuAppeared, "Pop-up menu should appear after tapping hamburger")
    }
}
