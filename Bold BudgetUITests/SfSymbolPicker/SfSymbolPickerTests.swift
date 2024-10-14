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
        MockAuthenticationProvider.test(using: .signedIn, in: &app.launchEnvironment)
        app.launch()

        // Navigate to SfSymbolPickerView
        app.buttons["DashboardView.AddTransactionButton"].tap()
        let collectionViewsQuery = app.collectionViews
        collectionViewsQuery.buttons["AddTransactionView.CategoryField.SelectCategoryButton"].tap()
        app.buttons["TransactionCategoryPickerView.AddCategoryButton"].tap()
        collectionViewsQuery.buttons["AddTransactionCategoryView.SymbolField.SelectSymbolButton"].tap()
        
        app.textFields["SfSymbolPickerView.SearchArea"].tap()
        app.textFields["SfSymbolPickerView.SearchArea"].clearAndEnterText("iPhone")
        XCTAssertTrue(app.scrollViews.otherElements/*@START_MENU_TOKEN@*/.images["iphone.gen1"]/*[[".buttons[\"iphone.gen1\"].images[\"iphone.gen1\"]",".images[\"iphone.gen1\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)
    }
}
