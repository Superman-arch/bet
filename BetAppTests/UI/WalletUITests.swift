import XCTest

class WalletUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skipOnboarding"]
        app.launchEnvironment = [
            "IS_TESTING": "1",
            "MOCK_USER": "true",
            "INITIAL_BALANCE": "1000"
        ]
        app.launch()
        
        // Navigate to Wallet tab
        app.tabBars.buttons["Wallet"].tap()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Balance Display Tests
    
    func testWalletBalanceDisplay() {
        // Verify balance card exists
        XCTAssertTrue(app.staticTexts["Total Balance"].exists)
        XCTAssertTrue(app.staticTexts["Withdrawable"].exists)
        
        // Verify balance amounts
        XCTAssertTrue(app.staticTexts["1000"].exists) // Total balance
        XCTAssertTrue(app.staticTexts["800 tokens"].exists) // Withdrawable
        
        // Test info button
        app.buttons["info.circle"].tap()
        XCTAssertTrue(app.staticTexts["Balance Information"].exists)
        app.buttons["OK"].tap()
    }
    
    func testActionButtons() {
        // Verify action buttons
        XCTAssertTrue(app.buttons["Add Tokens"].exists)
        XCTAssertTrue(app.buttons["Withdraw"].exists)
        
        // Verify withdraw button is enabled when balance > 0
        XCTAssertTrue(app.buttons["Withdraw"].isEnabled)
    }
    
    // MARK: - Add Tokens Tests
    
    func testAddTokensFlow() {
        // Tap Add Tokens
        app.buttons["Add Tokens"].tap()
        
        // Verify token packages
        XCTAssertTrue(app.staticTexts["Select Token Package"].exists)
        XCTAssertTrue(app.staticTexts["500 tokens"].exists)
        XCTAssertTrue(app.staticTexts["1100 tokens (+10% bonus)"].exists)
        XCTAssertTrue(app.staticTexts["MOST POPULAR"].exists)
        
        // Select a package
        app.buttons["2800 tokens (+12% bonus)"].tap()
        
        // Verify selection and price
        XCTAssertTrue(app.staticTexts["$25.00"].exists)
        XCTAssertTrue(app.buttons["Purchase Tokens"].isEnabled)
    }
    
    func testTokenPurchaseProcess() {
        app.buttons["Add Tokens"].tap()
        
        // Select package
        app.buttons["1100 tokens (+10% bonus)"].tap()
        
        // Purchase
        app.buttons["Purchase Tokens"].tap()
        
        // In test mode, this would mock Stripe
        sleep(2) // Wait for mock purchase
        
        // Should return to wallet with updated balance
        XCTAssertTrue(app.staticTexts["2100"].exists) // 1000 + 1100
    }
    
    // MARK: - Withdraw Tests
    
    func testWithdrawFlow() {
        // Tap Withdraw
        app.buttons["Withdraw"].tap()
        
        // Verify withdraw screen
        XCTAssertTrue(app.staticTexts["Withdrawable Balance"].exists)
        XCTAssertTrue(app.staticTexts["800 tokens"].exists)
        XCTAssertTrue(app.staticTexts["($8.00)"].exists)
        
        // Enter amount
        app.textFields["Amount to withdraw"].tap()
        app.textFields["Amount to withdraw"].typeText("500")
        
        // Verify conversion display
        XCTAssertTrue(app.staticTexts["You will receive: $5.00"].exists)
        
        // Verify button is enabled
        XCTAssertTrue(app.buttons["Withdraw to Bank"].isEnabled)
    }
    
    func testWithdrawValidation() {
        app.buttons["Withdraw"].tap()
        
        // Enter amount exceeding balance
        app.textFields["Amount to withdraw"].tap()
        app.textFields["Amount to withdraw"].typeText("1000")
        
        // Verify error message
        XCTAssertTrue(app.staticTexts["Insufficient withdrawable balance"].exists)
        
        // Verify button is disabled
        XCTAssertFalse(app.buttons["Withdraw to Bank"].isEnabled)
    }
    
    // MARK: - Transaction History Tests
    
    func testTransactionHistoryDisplay() {
        // Scroll to transaction history
        app.swipeUp()
        
        // Verify section header
        XCTAssertTrue(app.staticTexts["Transaction History"].exists)
        
        // In test mode with transactions
        if app.staticTexts["Deposit"].exists {
            // Verify transaction elements
            XCTAssertTrue(app.images["arrow.down.circle.fill"].exists)
            XCTAssertTrue(app.staticTexts["+500"].exists)
        } else {
            // Verify empty state
            XCTAssertTrue(app.staticTexts["No Transactions Yet"].exists)
        }
    }
    
    func testTransactionDetails() {
        app.swipeUp()
        
        // If transactions exist
        if app.staticTexts["Match Winnings"].exists {
            // Verify transaction row elements
            let transactionRow = app.cells.firstMatch
            XCTAssertTrue(transactionRow.images["trophy.fill"].exists)
            XCTAssertTrue(transactionRow.staticTexts["Match Winnings"].exists)
            XCTAssertTrue(transactionRow.staticTexts["+300"].exists)
        }
    }
    
    // MARK: - Pull to Refresh Tests
    
    func testPullToRefresh() {
        // Pull down to refresh
        let firstCell = app.cells.firstMatch
        let start = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let finish = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 6))
        start.press(forDuration: 0, thenDragTo: finish)
        
        // Verify refresh indicator appears
        sleep(1) // Wait for refresh
        
        // Balance should be refreshed
        XCTAssertTrue(app.staticTexts["Total Balance"].exists)
    }
    
    // MARK: - Edge Cases
    
    func testZeroBalance() {
        // Set up with zero balance
        app.launchEnvironment["INITIAL_BALANCE"] = "0"
        app.launch()
        app.tabBars.buttons["Wallet"].tap()
        
        // Verify withdraw button is disabled
        XCTAssertFalse(app.buttons["Withdraw"].isEnabled)
        
        // Verify zero balance display
        XCTAssertTrue(app.staticTexts["0"].exists)
    }
    
    func testLargeBalance() {
        // Set up with large balance
        app.launchEnvironment["INITIAL_BALANCE"] = "999999"
        app.launch()
        app.tabBars.buttons["Wallet"].tap()
        
        // Verify balance formats correctly
        XCTAssertTrue(app.staticTexts["999999"].exists)
    }
}