import XCTest

class OnboardingUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = ["IS_TESTING": "1"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Welcome Screen Tests
    
    func testWelcomeScreenElements() {
        // Verify welcome screen elements
        XCTAssertTrue(app.staticTexts["Welcome to Bet"].exists)
        XCTAssertTrue(app.staticTexts["Social wagering with friends"].exists)
        XCTAssertTrue(app.buttons["Get Started"].exists)
        
        // Verify feature rows
        XCTAssertTrue(app.staticTexts["Compete with Friends"].exists)
        XCTAssertTrue(app.staticTexts["Win Tokens"].exists)
        XCTAssertTrue(app.staticTexts["Safe & Secure"].exists)
    }
    
    func testNavigateToAgeVerification() {
        // Tap Get Started
        app.buttons["Get Started"].tap()
        
        // Verify age verification screen
        XCTAssertTrue(app.staticTexts["Verify Your Age"].exists)
        XCTAssertTrue(app.staticTexts["You must be 18 or older to use Bet"].exists)
        XCTAssertTrue(app.buttons["Continue"].exists)
    }
    
    // MARK: - Age Verification Tests
    
    func testAgeVerificationUnderAge() {
        navigateToAgeVerification()
        
        // Set date to make user under 18
        let datePicker = app.datePickers.firstMatch
        datePicker.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "January")
        datePicker.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "1")
        datePicker.pickerWheels.element(boundBy: 2).adjust(toPickerWheelValue: "2010")
        
        // Verify warning message
        XCTAssertTrue(app.staticTexts["You must be at least 18 years old"].exists)
        
        // Verify Continue button is disabled
        XCTAssertFalse(app.buttons["Continue"].isEnabled)
    }
    
    func testAgeVerificationValidAge() {
        navigateToAgeVerification()
        
        // Set date to make user over 18
        let datePicker = app.datePickers.firstMatch
        datePicker.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "January")
        datePicker.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "1")
        datePicker.pickerWheels.element(boundBy: 2).adjust(toPickerWheelValue: "2000")
        
        // Verify Continue button is enabled
        XCTAssertTrue(app.buttons["Continue"].isEnabled)
        
        // Continue to next screen
        app.buttons["Continue"].tap()
        
        // Verify region selection screen
        XCTAssertTrue(app.staticTexts["Select Your Region"].exists)
    }
    
    // MARK: - Region Selection Tests
    
    func testRegionSelection() {
        navigateToRegionSelection()
        
        // Verify region list
        XCTAssertTrue(app.buttons["United States"].exists)
        XCTAssertTrue(app.buttons["Canada"].exists)
        XCTAssertTrue(app.buttons["United Kingdom"].exists)
        
        // Select a region
        app.buttons["United States"].tap()
        
        // Verify selection
        XCTAssertTrue(app.images["checkmark.circle.fill"].exists)
        
        // Verify Continue button is enabled
        XCTAssertTrue(app.buttons["Continue"].isEnabled)
    }
    
    func testAutoDetectLocation() {
        navigateToRegionSelection()
        
        // Tap auto-detect
        app.buttons["Detect Automatically"].tap()
        
        // In test environment, this would mock location
        // Verify a region is selected
        sleep(1) // Wait for mock location
    }
    
    // MARK: - Account Creation Tests
    
    func testAccountCreationValidation() {
        navigateToAccountCreation()
        
        // Verify all fields exist
        XCTAssertTrue(app.textFields["Username"].exists)
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.textFields["Phone (Optional)"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertTrue(app.secureTextFields["Confirm Password"].exists)
        
        // Test empty fields
        XCTAssertFalse(app.buttons["Create Account"].isEnabled)
        
        // Fill in fields
        app.textFields["Username"].tap()
        app.textFields["Username"].typeText("testuser123")
        
        app.textFields["Email"].tap()
        app.textFields["Email"].typeText("test@example.com")
        
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("SecurePass123!")
        
        app.secureTextFields["Confirm Password"].tap()
        app.secureTextFields["Confirm Password"].typeText("SecurePass123!")
        
        // Verify Create Account is enabled
        XCTAssertTrue(app.buttons["Create Account"].isEnabled)
    }
    
    func testPasswordMismatch() {
        navigateToAccountCreation()
        
        // Fill in fields with mismatched passwords
        fillAccountFields(
            username: "testuser",
            email: "test@example.com",
            password: "Password123!",
            confirmPassword: "DifferentPass123!"
        )
        
        // Verify button is disabled
        XCTAssertFalse(app.buttons["Create Account"].isEnabled)
    }
    
    func testInvalidEmail() {
        navigateToAccountCreation()
        
        // Fill with invalid email
        fillAccountFields(
            username: "testuser",
            email: "invalidemail",
            password: "Password123!",
            confirmPassword: "Password123!"
        )
        
        // Verify button is disabled
        XCTAssertFalse(app.buttons["Create Account"].isEnabled)
    }
    
    func testSuccessfulAccountCreation() {
        navigateToAccountCreation()
        
        // Fill valid data
        fillAccountFields(
            username: "testuser\(Int.random(in: 1000...9999))",
            email: "test\(Int.random(in: 1000...9999))@example.com",
            password: "SecurePass123!",
            confirmPassword: "SecurePass123!"
        )
        
        // Create account
        app.buttons["Create Account"].tap()
        
        // In test mode, this would mock the creation
        // Verify navigation to main app
        sleep(2) // Wait for mock creation
        
        // Should see main tab bar
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
    
    // MARK: - Helper Methods
    
    private func navigateToAgeVerification() {
        app.buttons["Get Started"].tap()
    }
    
    private func navigateToRegionSelection() {
        navigateToAgeVerification()
        
        // Set valid age
        let datePicker = app.datePickers.firstMatch
        datePicker.pickerWheels.element(boundBy: 2).adjust(toPickerWheelValue: "2000")
        app.buttons["Continue"].tap()
    }
    
    private func navigateToAccountCreation() {
        navigateToRegionSelection()
        
        // Select region
        app.buttons["United States"].tap()
        app.buttons["Continue"].tap()
    }
    
    private func fillAccountFields(
        username: String,
        email: String,
        password: String,
        confirmPassword: String
    ) {
        app.textFields["Username"].tap()
        app.textFields["Username"].typeText(username)
        
        app.textFields["Email"].tap()
        app.textFields["Email"].typeText(email)
        
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText(password)
        
        app.secureTextFields["Confirm Password"].tap()
        app.secureTextFields["Confirm Password"].typeText(confirmPassword)
    }
}