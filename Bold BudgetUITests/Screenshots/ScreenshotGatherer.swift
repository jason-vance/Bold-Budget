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
        MockBudgetFetcher.test(usingSample: true, in: &app.launchEnvironment)
        MockTransactionFetcher.test(using: .screenshotSamples, in: &app.launchEnvironment)
        MockTransactionCategoryRepo.test(using: .categorySamples, in: &app.launchEnvironment)
        app.launch()
        
        // Budget List
        app.buttons["BudgetsListView.BudgetRow.Test Budget"].tap()
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Dashboard"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testAddTransactionScreenshot() throws {
        let app = XCUIApplication()
        MockAuthenticationProvider.test(using: .signedIn, in: &app.launchEnvironment)
        MockBudgetFetcher.test(usingSample: true, in: &app.launchEnvironment)
        MockTransactionFetcher.test(using: .screenshotSamples, in: &app.launchEnvironment)
        MockTransactionCategoryRepo.test(using: .singleCategory_Groceries, in: &app.launchEnvironment)
        app.launch()
        
        // Budget List
        app.buttons["BudgetsListView.BudgetRow.Test Budget"].tap()
        
        // Dashboard
        app.buttons["DashboardView.AddTransactionButton"].tap()

        // AddTransaction
        app.collectionViews.buttons["AddTransactionView.CategoryField.SelectCategoryButton"].tap()

        // CategoryPicker
        app.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["Groceries"]/*[[".buttons[\"Groceries\"].staticTexts[\"Groceries\"]",".staticTexts[\"Groceries\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        // AddTransaction
        app.collectionViews.textFields["AddTransactionView.AmountField.TextField"].tap()
        app.collectionViews.textFields["AddTransactionView.AmountField.TextField"].clearAndEnterText("$87.63")
        app.collectionViews.textFields["AddTransactionView.TitleField.TextField"].tap()
        app.collectionViews.textFields["AddTransactionView.TitleField.TextField"].typeText("Walmart")
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "AddTransaction"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testTransactionDetailScreenshot() throws {
        let app = XCUIApplication()
        MockAuthenticationProvider.test(using: .signedIn, in: &app.launchEnvironment)
        MockBudgetFetcher.test(usingSample: true, in: &app.launchEnvironment)
        MockTransactionFetcher.test(using: .screenshotSamples, in: &app.launchEnvironment)
        MockTransactionCategoryRepo.test(using: .categorySamples, in: &app.launchEnvironment)
        app.launch()
        
        // Budget List
        app.buttons["BudgetsListView.BudgetRow.Test Budget"].tap()
        
        app.collectionViews.staticTexts["Gas"].tap()
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "TransactionDetail"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
