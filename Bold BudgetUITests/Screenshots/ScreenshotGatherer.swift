//
//  ScreenshotGatherer.swift
//  Bold BudgetUITests
//
//  Created by Jason Vance on 10/6/24.
//

import XCTest

final class ScreenshotGatherer: XCTestCase {
    
    private var app: XCUIApplication! = nil

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testDashboardScreenshot() throws {
        let app = XCUIApplication()
        MockAuthenticationProvider.test(using: .signedIn, in: &app.launchEnvironment)
        TransactionCategoryRepo.test(using: .categorySamples, in: &app.launchEnvironment)
        TransactionLedger.test(using: .screenshotSamples, in: &app.launchEnvironment)
        app.launch()
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Dashboard"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testAddTransactionScreenshot() throws {
        let app = XCUIApplication()
        MockAuthenticationProvider.test(using: .signedIn, in: &app.launchEnvironment)
        TransactionCategoryRepo.test(using: .empty, in: &app.launchEnvironment)
        TransactionLedger.test(using: .empty, in: &app.launchEnvironment)
        app.launch()
        
        // Dashboard
        app.buttons["DashboardView.AddTransactionButton"].tap()

        // AddTransaction
        app.collectionViews.buttons["AddTransactionView.CategoryField.SelectCategoryButton"].tap()

        // CategoryPicker
        app.buttons["TransactionCategoryPickerView.AddCategoryButton"].tap()

        // AddCategory
        app.collectionViews.textFields["AddTransactionCategoryView.NameField.TextField"].tap()
        app.collectionViews.textFields["AddTransactionCategoryView.NameField.TextField"].typeText("Groceries")
        app.collectionViews.buttons["AddTransactionCategoryView.SymbolField.SelectSymbolButton"].tap()
        
        // SfSymbolPicker
        app.textFields["SfSymbolPickerView.SearchArea"].tap()
        app.textFields["SfSymbolPickerView.SearchArea"].typeText("bag")
        app.scrollViews.otherElements.buttons["bag.fill"].tap()
        
        // AddCategory
        app.buttons["AddTransactionCategoryView.Toolbar.SaveButton"].tap()
        
        // CategoryPicker
        app.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["Groceries"]/*[[".buttons[\"Groceries\"].staticTexts[\"Groceries\"]",".staticTexts[\"Groceries\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        // AddTransaction
        app.collectionViews.textFields["AddTransactionView.AmountField.TextField"].tap()
        app.collectionViews.textFields["AddTransactionView.AmountField.TextField"].clearAndEnterText("$87.63")
        app.collectionViews.textFields["AddTransactionView.TitleField.TextField"].tap()
        app.collectionViews.textFields["AddTransactionView.TitleField.TextField"].typeText("Walmart")
        app.collectionViews.textFields["AddTransactionView.LocationField.TextField"].tap()
        app.collectionViews.textFields["AddTransactionView.LocationField.TextField"].typeText("Seattle, WA")
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "AddTransaction"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testTransactionDetailScreenshot() throws {
        let app = XCUIApplication()
        MockAuthenticationProvider.test(using: .signedIn, in: &app.launchEnvironment)
        TransactionCategoryRepo.test(using: .categorySamples, in: &app.launchEnvironment)
        TransactionLedger.test(using: .screenshotSamples, in: &app.launchEnvironment)
        app.launch()
        
        app.collectionViews.staticTexts["Gas"].tap()
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "TransactionDetail"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
