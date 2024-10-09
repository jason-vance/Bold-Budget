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
        TransactionCategoryRepo.test(using: .categorySamples, in: &app.launchEnvironment)
        TransactionLedger.test(using: .transactionSamples, in: &app.launchEnvironment)
        app.launch()
        
        XCTAssertTrue(app.collectionViews.staticTexts["Net Total"].exists)
        XCTAssertFalse(app.collectionViews.staticTexts["$0.00"].exists)
    }
    
    func testShowsCategoryNameWhenSliceIsTapped() throws {
        let app = XCUIApplication()
        TransactionCategoryRepo.test(using: .categorySamples, in: &app.launchEnvironment)
        TransactionLedger.test(using: .transactionSamples, in: &app.launchEnvironment)
        app.launch()
        
        XCUIApplication().collectionViews.images["PieChart.SliceView.Housing"].tap()
                
        XCTAssertTrue(app.collectionViews.staticTexts["Housing"].exists)
        XCTAssertFalse(app.collectionViews.staticTexts["$0.00"].exists)
    }
    
    func testShowsCategoryNameWhenThereIsOneCategory() throws {
        let app = XCUIApplication()
        TransactionCategoryRepo.test(using: .singleCategory_Groceries, in: &app.launchEnvironment)
        TransactionLedger.test(using: .onlyGroceryTransactions, in: &app.launchEnvironment)
        app.launch()
        
        XCTAssertTrue(app.collectionViews.images["PieChart.SingleSliceView.Groceries"].exists)
        XCTAssertTrue(app.collectionViews.staticTexts["Groceries"].exists)
        XCTAssertFalse(app.collectionViews.staticTexts["$0.00"].exists)
    }
}
