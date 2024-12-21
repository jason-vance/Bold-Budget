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
        MockCurrentUserDataProvider.test(usingSample: true, in: &app.launchEnvironment)
        MockCurrentUserIdProvider.test(using: .sample, in: &app.launchEnvironment)
        MockBudgetFetcher.test(usingSample: true, in: &app.launchEnvironment)
        app.launch()

        // Navigate to SfSymbolPickerView
        app.buttons["BudgetsListView.BudgetRow.Family Budget"].tap()
        _ = app.buttons["DashboardView.AddTransactionButton"].waitForExistence(timeout: 2)
        app.buttons["DashboardView.AddTransactionButton"].tap()
        let collectionViewsQuery = app.collectionViews
        _ = collectionViewsQuery.buttons["EditTransactionView.CategoryField.SelectCategoryButton"].waitForExistence(timeout: 2)
        collectionViewsQuery.buttons["EditTransactionView.CategoryField.SelectCategoryButton"].tap()
        app.buttons["TransactionCategoryPickerView.AddCategoryButton"].tap()
        collectionViewsQuery.buttons["EditTransactionCategoryView.SymbolField.SelectSymbolButton"].tap()
        
        app.textFields["SfSymbolPickerView.SearchArea"].tap()
        app.textFields["SfSymbolPickerView.SearchArea"].clearAndEnterText("iPhone")
        XCTAssertTrue(app.scrollViews.otherElements/*@START_MENU_TOKEN@*/.images["iphone.gen1"]/*[[".buttons[\"iphone.gen1\"].images[\"iphone.gen1\"]",".images[\"iphone.gen1\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)
    }
}
