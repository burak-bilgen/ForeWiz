import XCTest

final class ForeWizUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testAppLaunchesSuccessfully() throws {
        let app = XCUIApplication()
        app.launch()
        
        let splashScreen = app.otherElements.matching(identifier: "splashScreen").firstMatch
        if splashScreen.exists {
            let exists = NSPredicate(format: "exists == 0")
            expectation(for: exists, evaluatedWith: splashScreen, handler: nil)
            waitForExpectations(timeout: 5)
        }
        
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }

    @MainActor
    func testHomeScreenDisplays() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding"]
        app.launch()
        
        let timeout = 10.0
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: timeout))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
