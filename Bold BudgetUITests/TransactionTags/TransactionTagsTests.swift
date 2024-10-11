//
//  TransactionTagsTests.swift
//  Bold BudgetUITests
//
//  Created by Jason Vance on 10/11/24.
//

import XCTest

final class TransactionTagsTests: XCTestCase {

    func testExample() throws {
        let app = XCUIApplication()
        TransactionCategoryRepo.test(using: .categorySamples, in: &app.launchEnvironment)
        TransactionLedger.test(using: .transactionSamples, in: &app.launchEnvironment)
        app.launch()
        
        // Dashboard
        app/*@START_MENU_TOKEN@*/.buttons["Add Transaction Button"]/*[[".buttons[\"Add\"]",".buttons[\"Add Transaction Button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        // Add Transaction
        app.collectionViews/*@START_MENU_TOKEN@*/.buttons["N/A"]/*[[".cells.buttons[\"N\/A\"]",".buttons[\"N\/A\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        // Category Picker
        app.scrollViews.otherElements/*@START_MENU_TOKEN@*/.staticTexts["Groceries"]/*[[".buttons[\"Groceries\"].staticTexts[\"Groceries\"]",".staticTexts[\"Groceries\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        // Add Transaction
        app.collectionViews.textFields["AddTransactionView.AmountField.TextField"].tap()
        app.collectionViews.textFields["AddTransactionView.AmountField.TextField"].typeText("1")
        
        app.collectionViews.textFields["AddTransactionView.TagsField.TextField"].tap()
        app.collectionViews.textFields["AddTransactionView.TagsField.TextField"].clearAndEnterText("Test Tag")
        app.collectionViews/*@START_MENU_TOKEN@*/.buttons["Add"]/*[[".cells.buttons[\"Add\"]",".buttons[\"Add\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        XCTAssertTrue(app.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["Test Tag"]/*[[".cells.staticTexts[\"Test Tag\"]",".staticTexts[\"Test Tag\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)

        app/*@START_MENU_TOKEN@*/.buttons["checkmark"]/*[[".buttons[\"Selected\"]",".buttons[\"checkmark\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        // Dashboard
        app.collectionViews.buttons["Groceries, $10.00, Today"].tap()
        XCTAssertTrue(app.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["Test Tag"]/*[[".cells.staticTexts[\"Test Tag\"]",".staticTexts[\"Test Tag\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)
        app.buttons["xmark"].tap()
        
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .button).matching(identifier: "line.3.horizontal.decrease").element(boundBy: 1).tap()
        
        // Transaction Filter Menu
        app.collectionViews/*@START_MENU_TOKEN@*/.images["tag"]/*[[".cells",".buttons[\"Tag, Add\"]",".images[\"Tag\"]",".images[\"tag\"]"],[[[-1,3],[-1,2],[-1,1,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1,2]],[[-1,3],[-1,2]]],[0]]@END_MENU_TOKEN@*/.tap()
        XCTAssertTrue(app.scrollViews.otherElements/*@START_MENU_TOKEN@*/.staticTexts["Test Tag"]/*[[".buttons[\"Test Tag\"].staticTexts[\"Test Tag\"]",".staticTexts[\"Test Tag\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)
        app.scrollViews.otherElements/*@START_MENU_TOKEN@*/.staticTexts["Test Tag"]/*[[".buttons[\"Test Tag\"].staticTexts[\"Test Tag\"]",".staticTexts[\"Test Tag\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        XCTAssertTrue(app.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["Test Tag"]/*[[".cells.staticTexts[\"Test Tag\"]",".staticTexts[\"Test Tag\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)
        app.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["Test Tag"]/*[[".cells.staticTexts[\"Test Tag\"]",".staticTexts[\"Test Tag\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        XCTAssertFalse(app.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["Test Tag"]/*[[".cells.staticTexts[\"Test Tag\"]",".staticTexts[\"Test Tag\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)
    }
}
