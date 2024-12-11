//
//  PieChartTests.swift
//  Bold BudgetUITests
//
//  Created by Jason Vance on 10/8/24.
//

import XCTest

final class PieChartTests: XCTestCase {
    
    func testShowsNetTotalWhenThereAreMultipleCategories() throws {
        let app = XCUIApplication()
        MockAuthenticationProvider.test(using: .signedIn, in: &app.launchEnvironment)
        MockCurrentUserDataProvider.test(usingSample: true, in: &app.launchEnvironment)
        MockCurrentUserIdProvider.test(using: .sample, in: &app.launchEnvironment)
        MockBudgetFetcher.test(usingSample: true, in: &app.launchEnvironment)
        MockTransactionFetcher.test(using: .samples, in: &app.launchEnvironment)
        MockTransactionCategoryRepo.test(using: .categorySamples, in: &app.launchEnvironment)
        app.launch()
        
        // Budget List
        app.buttons["BudgetsListView.BudgetRow.Family Budget"].tap()
        
        // Budget Detail
        XCTAssertTrue(app.collectionViews.staticTexts["Net Total"].exists)
        XCTAssertFalse(app.collectionViews.staticTexts["$0.00"].exists)
    }
    
    func testShowsCategoryNameWhenSliceIsTapped() throws {
        let app = XCUIApplication()
        MockAuthenticationProvider.test(using: .signedIn, in: &app.launchEnvironment)
        MockCurrentUserDataProvider.test(usingSample: true, in: &app.launchEnvironment)
        MockCurrentUserIdProvider.test(using: .sample, in: &app.launchEnvironment)
        MockBudgetFetcher.test(usingSample: true, in: &app.launchEnvironment)
        MockTransactionFetcher.test(using: .samples, in: &app.launchEnvironment)
        MockTransactionCategoryRepo.test(using: .categorySamples, in: &app.launchEnvironment)
        app.launch()
        
        // Budget List
        app.buttons["BudgetsListView.BudgetRow.Family Budget"].tap()
        
        _ = app.collectionViews.images["PieChart.SliceView.Housing"].waitForExistence(timeout: 2)
        app.collectionViews.images["PieChart.SliceView.Housing"].tap()
                
        XCTAssertTrue(app.collectionViews.staticTexts["Housing"].exists)
        XCTAssertFalse(app.collectionViews.staticTexts["$0.00"].exists)
    }
}
