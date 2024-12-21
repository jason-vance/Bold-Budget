//
//  TransactionTagsTests.swift
//  Bold BudgetUITests
//
//  Created by Jason Vance on 10/11/24.
//

import XCTest

final class TransactionTagsTests: XCTestCase {
    
    func testTransactionTagAppearsInAddTransactionView() throws {
        let app = XCUIApplication()
        MockAuthenticationProvider.test(using: .signedIn, in: &app.launchEnvironment)
        MockCurrentUserDataProvider.test(usingSample: true, in: &app.launchEnvironment)
        MockCurrentUserIdProvider.test(using: .sample, in: &app.launchEnvironment)
        MockBudgetFetcher.test(usingSample: true, in: &app.launchEnvironment)
        MockTransactionCategoryRepo.test(using: .categorySamples, in: &app.launchEnvironment)
        app.launch()
        
        // Budget List
        app.buttons["BudgetsListView.BudgetRow.Family Budget"].tap()
        
        // Dashboard
        _ = app.buttons["DashboardView.AddTransactionButton"].waitForExistence(timeout: 2)
        app.buttons["DashboardView.AddTransactionButton"].tap()

        // Add Transaction
        app.collectionViews.textFields["EditTransactionView.AmountField.TextField"].tap()
        app.collectionViews.textFields["EditTransactionView.AmountField.TextField"].typeText("1")
        
        app.collectionViews.textFields["EditTransactionView.TagsField.TextField"].tap()
        app.collectionViews.textFields["EditTransactionView.TagsField.TextField"].clearAndEnterText("Test Tag")
        app.collectionViews.buttons["EditTransactionView.TagsField.SaveNewTagButton"].tap()
        
        XCTAssertTrue(app.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["Test Tag"]/*[[".cells.staticTexts[\"Test Tag\"]",".staticTexts[\"Test Tag\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)
    }
    
    func testTransactionTagAppearsInTransactionDetailView() throws {
        let app = XCUIApplication()
        MockAuthenticationProvider.test(using: .signedIn, in: &app.launchEnvironment)
        MockCurrentUserDataProvider.test(usingSample: true, in: &app.launchEnvironment)
        MockCurrentUserIdProvider.test(using: .sample, in: &app.launchEnvironment)
        MockBudgetFetcher.test(usingSample: true, in: &app.launchEnvironment)
        MockTransactionFetcher.test(using: .taggedSample, in: &app.launchEnvironment)
        MockTransactionCategoryRepo.test(using: .categorySamples, in: &app.launchEnvironment)
        app.launch()
        
        // Budget List
        app.buttons["BudgetsListView.BudgetRow.Family Budget"].tap()
        
        // BudgetDetailView
        _ = app.buttons["Groceries, $10.00, Today"].waitForExistence(timeout: 2)
        app.buttons["Groceries, $10.00, Today"].tap()
        
        // Transaction Detail
        XCTAssertTrue(app.collectionViews.staticTexts["Beach Trip"].exists)
    }
    
    func testTransactionTagAppearsInTransactionTagPickerView() throws {
        let app = XCUIApplication()
        MockAuthenticationProvider.test(using: .signedIn, in: &app.launchEnvironment)
        MockCurrentUserDataProvider.test(usingSample: true, in: &app.launchEnvironment)
        MockCurrentUserIdProvider.test(using: .sample, in: &app.launchEnvironment)
        MockBudgetFetcher.test(usingSample: true, in: &app.launchEnvironment)
        MockTransactionFetcher.test(using: .taggedSample, in: &app.launchEnvironment)
        MockTransactionCategoryRepo.test(using: .categorySamples, in: &app.launchEnvironment)
        app.launch()
        
        // Budget List
        app.buttons["BudgetsListView.BudgetRow.Family Budget"].tap()
        
        // Dashboard
        app.buttons["DashboardView.FilterTransactionsButton"].tap()
        
        // Transaction Filter Menu
        app.buttons["TransactionsFilterMenu.TagsFieldButton"].tap()
        
        // TransactionTagPickerView
        XCTAssertTrue(app.scrollViews.otherElements.staticTexts["Beach Trip"].exists)
    }
    
    func testSelectedTransactionTagAppearsInTransactionsFilterMenu() throws {
        let app = XCUIApplication()
        MockAuthenticationProvider.test(using: .signedIn, in: &app.launchEnvironment)
        MockCurrentUserDataProvider.test(usingSample: true, in: &app.launchEnvironment)
        MockCurrentUserIdProvider.test(using: .sample, in: &app.launchEnvironment)
        MockBudgetFetcher.test(usingSample: true, in: &app.launchEnvironment)
        MockTransactionFetcher.test(using: .taggedSample, in: &app.launchEnvironment)
        MockTransactionCategoryRepo.test(using: .categorySamples, in: &app.launchEnvironment)
        app.launch()
        
        // Budget List
        app.buttons["BudgetsListView.BudgetRow.Family Budget"].tap()
        
        // Dashboard
        app.buttons["DashboardView.FilterTransactionsButton"].tap()

        // Transaction Filter Menu
        app.buttons["TransactionsFilterMenu.TagsFieldButton"].tap()
        
        // TransactionTagPickerView
        _ = app.scrollViews.otherElements.staticTexts["Beach Trip"].waitForExistence(timeout: 2)
        app.scrollViews.otherElements.staticTexts["Beach Trip"].tap()
        
        // Transaction Filter Menu
        XCTAssertTrue(app.collectionViews.staticTexts["Beach Trip"].exists)
    }
}
