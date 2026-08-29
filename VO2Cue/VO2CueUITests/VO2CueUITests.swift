import XCTest

final class VO2CueUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-healthSavingEnabled", "NO"]
        app.launch()
    }

    func testCreateCustomProfile() {
        app.buttons["New Workout"].tap()
        XCTAssertTrue(app.navigationBars["Workout profile"].waitForExistence(timeout: 3))

        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.exists)
        nameField.tap()
        nameField.clearAndType("Pool 4×4")
        app.navigationBars["Workout profile"].buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Pool 4×4"].waitForExistence(timeout: 3))
    }

    func testWorkoutControlsAndHistory() {
        app.staticTexts["Norwegian 4×4"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Norwegian 4×4"].waitForExistence(timeout: 3))

        let startButton = app.buttons["Start workout"]
        while !startButton.isHittable {
            app.swipeUp()
        }
        startButton.tap()

        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 3))
        pauseButton.tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 2))
        app.buttons["Resume"].tap()
        app.buttons["Skip"].tap()
        app.buttons["End"].tap()
        XCTAssertTrue(app.buttons["End workout"].waitForExistence(timeout: 2))
        app.buttons["End workout"].tap()

        XCTAssertTrue(app.staticTexts["Workout ended"].waitForExistence(timeout: 3))
        app.buttons["Done"].tap()
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["Norwegian 4×4"].waitForExistence(timeout: 3))
    }
}

private extension XCUIElement {
    func clearAndType(_ text: String) {
        guard let current = value as? String else {
            typeText(text)
            return
        }
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        typeText(text)
    }
}
