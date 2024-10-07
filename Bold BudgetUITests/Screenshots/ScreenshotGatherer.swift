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
        TransactionCategoryRepo.test(using: .empty, in: &app.launchEnvironment)
        TransactionLedger.test(using: .empty, in: &app.launchEnvironment)
        app.launch()
        
        // Dashboard
        app.windows.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .button).matching(identifier: "plus").element(boundBy: 1).tap()
        
        // AddTransaction
        app.collectionViews.buttons["N/A"].tap()
        
        // CategoryPicker
        app.buttons["Add Category Button"].tap()
        
        // AddCategory
        app.collectionViews.textFields["Groceries, Rent, Paycheck, etc..."].tap()
        app.collectionViews.textFields["Groceries, Rent, Paycheck, etc..."].typeText("Groceries")
        app.collectionViews.buttons["Symbol Picker Button"].tap()
        
        // SfSymbolPicker
        app.textFields["Search for a symbol"].tap()
        app.textFields["Search for a symbol"].typeText("bag")
        app.scrollViews.otherElements.buttons["bag.fill"].tap()
        
        // AddCategory
        app.buttons["Save Category Button"].tap()
        
        // CategoryPicker
        app.scrollViews.otherElements.staticTexts["Groceries"].tap()
        
        // AddTransaction
        app.collectionViews.textFields["$0.00"].tap()
        app.collectionViews.textFields["$0.00"].clearAndEnterText("$87.63")
        app.collectionViews.textFields["Milk Tea, Movie Tickets, etc..."].tap()
        app.collectionViews.textFields["Milk Tea, Movie Tickets, etc..."].typeText("Walmart")
        app.collectionViews.textFields["Cupertino, CA"].tap()
        app.collectionViews.textFields["Cupertino, CA"].typeText("Seattle, WA")
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "AddTransaction"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testTransactionDetailScreenshot() throws {
        let app = XCUIApplication()
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
