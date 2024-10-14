//
//  TransactionTagsTests.swift
//  Bold BudgetUITests
//
//  Created by Jason Vance on 10/11/24.
//

import XCTest

final class TransactionTagsTests: XCTestCase {

    func testTransactionTagUiWorksAsExpected() throws {
        let app = XCUIApplication()
        MockAuthenticationProvider.test(using: .signedIn, in: &app.launchEnvironment)
        TransactionCategoryRepo.test(using: .categorySamples, in: &app.launchEnvironment)
        TransactionLedger.test(using: .transactionSamples, in: &app.launchEnvironment)
        app.launch()
        
        // Dashboard
        app.buttons["DashboardView.AddTransactionButton"].tap()
        
        // Add Transaction
        app.collectionViews.buttons["AddTransactionView.CategoryField.SelectCategoryButton"].tap()
        
        // Category Picker
        app.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["Groceries"]/*[[".buttons[\"Groceries\"].staticTexts[\"Groceries\"]",".staticTexts[\"Groceries\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        // Add Transaction
        app.collectionViews.textFields["AddTransactionView.AmountField.TextField"].tap()
        app.collectionViews.textFields["AddTransactionView.AmountField.TextField"].typeText("1")
        
        app.collectionViews.textFields["AddTransactionView.TagsField.TextField"].tap()
        app.collectionViews.textFields["AddTransactionView.TagsField.TextField"].clearAndEnterText("Test Tag")
        app.collectionViews.buttons["AddTransactionView.TagsField.SaveNewTagButton"].tap()
        
        XCTAssertTrue(app.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["Test Tag"]/*[[".cells.staticTexts[\"Test Tag\"]",".staticTexts[\"Test Tag\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)

        app.buttons["AddTransactionView.Toolbar.SaveButton"].tap()
        
        // Dashboard
        app.collectionViews.buttons["Groceries, $10.00, Today"].tap()
        
        // Transaction Detail
        XCTAssertTrue(app.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["Test Tag"]/*[[".cells.staticTexts[\"Test Tag\"]",".staticTexts[\"Test Tag\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)
        app.buttons["TransactionDetailView.Toolbar.DismissButton"].tap()
        
        // Dashboard
        XCUIApplication().windows.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element/*@START_MENU_TOKEN@*/.children(matching: .button).matching(identifier: "DashboardView.FilterTransactionsButton").element(boundBy: 1)/*[[".children(matching: .button).matching(identifier: \"line.3.horizontal.decrease\").element(boundBy: 1)",".children(matching: .button).matching(identifier: \"DashboardView.FilterTransactionsButton\").element(boundBy: 1)"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        // Transaction Filter Menu
        app.collectionViews/*@START_MENU_TOKEN@*/.images["tag"]/*[[".cells",".buttons[\"Tag, Add\"]",".images[\"Tag\"]",".images[\"tag\"]"],[[[-1,3],[-1,2],[-1,1,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1,2]],[[-1,3],[-1,2]]],[0]]@END_MENU_TOKEN@*/.tap()
        XCTAssertTrue(app.scrollViews.otherElements/*@START_MENU_TOKEN@*/.staticTexts["Test Tag"]/*[[".buttons[\"Test Tag\"].staticTexts[\"Test Tag\"]",".staticTexts[\"Test Tag\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)
        app.scrollViews.otherElements/*@START_MENU_TOKEN@*/.staticTexts["Test Tag"]/*[[".buttons[\"Test Tag\"].staticTexts[\"Test Tag\"]",".staticTexts[\"Test Tag\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        XCTAssertTrue(app.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["Test Tag"]/*[[".cells.staticTexts[\"Test Tag\"]",".staticTexts[\"Test Tag\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)
        app.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["Test Tag"]/*[[".cells.staticTexts[\"Test Tag\"]",".staticTexts[\"Test Tag\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        XCTAssertFalse(app.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["Test Tag"]/*[[".cells.staticTexts[\"Test Tag\"]",".staticTexts[\"Test Tag\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)
    }
}
