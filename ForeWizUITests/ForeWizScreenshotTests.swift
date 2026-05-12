import XCTest

final class ForeWizScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testCaptureScreenshots() throws {
        sleep(3)
        snapshot("01-Home")

        let locationBtn = app.buttons["Choose location"]
        if locationBtn.waitForExistence(timeout: 3) {
            locationBtn.tap()
            sleep(2)
            snapshot("02-LocationPicker")
        }
    }
}
