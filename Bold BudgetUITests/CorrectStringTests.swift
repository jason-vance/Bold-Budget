//
//  CorrectStringTests.swift
//  Bold BudgetUITests
//
//  Created by Jason Vance on 9/28/24.
//

import XCTest

final class CorrectStringTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        let message = "A string passed in from the UI test"
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        StringProvider.setValueOf(string: message, in: &app.launchEnvironment)
        app.launch()
        
        XCTAssert(XCUIApplication().staticTexts[message].exists)
    }
}
