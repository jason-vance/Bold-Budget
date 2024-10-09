//
//  SfSymbolPickerTests.swift
//  Bold BudgetUITests
//
//  Created by Jason Vance on 10/8/24.
//

import XCTest

final class SfSymbolPickerTests: XCTestCase {

    func testSearchIsCaseAgnostic() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Navigate to SfSymbolPickerView
        app/*@START_MENU_TOKEN@*/.buttons["Add Transaction Button"]/*[[".buttons[\"Add\"]",".buttons[\"Add Transaction Button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        let collectionViewsQuery = app.collectionViews
        collectionViewsQuery/*@START_MENU_TOKEN@*/.buttons["N/A"]/*[[".cells.buttons[\"N\/A\"]",".buttons[\"N\/A\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.buttons["Add Category Button"]/*[[".buttons[\"Add\"]",".buttons[\"Add Category Button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        collectionViewsQuery/*@START_MENU_TOKEN@*/.buttons["Symbol Picker Button"]/*[[".cells",".buttons[\"N\/A\"]",".buttons[\"Symbol Picker Button\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        app.textFields["Search for a symbol"].clearAndEnterText("iPhone")
        XCTAssertTrue(app.scrollViews.otherElements/*@START_MENU_TOKEN@*/.images["iphone.gen1"]/*[[".buttons[\"iphone.gen1\"].images[\"iphone.gen1\"]",".images[\"iphone.gen1\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)
    }
}
