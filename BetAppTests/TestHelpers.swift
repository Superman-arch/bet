import XCTest
import SwiftUI
@testable import BetApp

// MARK: - Test Extensions

extension XCTestCase {
    
    /// Wait for an async operation with timeout
    func waitForAsync(
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line,
        operation: @escaping () async throws -> Void
    ) {
        let expectation = expectation(description: "Async operation")
        
        Task {
            do {
                try await operation()
                expectation.fulfill()
            } catch {
                XCTFail("Async operation failed: \(error)", file: file, line: line)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
    /// Create a test view environment
    func createTestEnvironment() -> (EnvironmentValues, ViewInspector) {
        let environment = EnvironmentValues()
        let inspector = ViewInspector()
        return (environment, inspector)
    }
}

// MARK: - View Inspector

class ViewInspector {
    func find<T: View>(_ viewType: T.Type, in view: AnyView) -> T? {
        // Implementation for finding views in SwiftUI hierarchy
        return nil
    }
    
    func findButton(labeled: String, in view: AnyView) -> Button<Text>? {
        // Implementation for finding buttons
        return nil
    }
    
    func findText(_ text: String, in view: AnyView) -> Text? {
        // Implementation for finding text
        return nil
    }
}

// MARK: - Test Doubles

protocol TestDouble {
    func reset()
}

class SpyAnalyticsManager: AnalyticsManager, TestDouble {
    var trackedEvents: [(event: String, properties: [String: Any]?)] = []
    var userProperties: [String: Any] = [:]
    var identifiedUserId: String?
    
    override func track(event: String, properties: [String: Any]? = nil) {
        trackedEvents.append((event: event, properties: properties))
    }
    
    override func setUserProperty(_ property: String, value: Any) {
        userProperties[property] = value
    }
    
    override func identifyUser(_ userId: String) {
        identifiedUserId = userId
    }
    
    func reset() {
        trackedEvents.removeAll()
        userProperties.removeAll()
        identifiedUserId = nil
    }
}

// MARK: - Test Configurations

struct TestConfiguration {
    static func configure(for testCase: XCTestCase) {
        // Set up test environment
        UserDefaults.standard.set(true, forKey: "IS_TESTING")
        UserDefaults.standard.set(true, forKey: "MOCK_PAYMENTS")
        UserDefaults.standard.set(true, forKey: "SKIP_ANIMATIONS")
        
        // Configure mock services
        configureMockServices()
    }
    
    private static func configureMockServices() {
        // Configure dependency injection for tests
    }
    
    static func tearDown() {
        // Clean up test environment
        UserDefaults.standard.removeObject(forKey: "IS_TESTING")
        UserDefaults.standard.removeObject(forKey: "MOCK_PAYMENTS")
        UserDefaults.standard.removeObject(forKey: "SKIP_ANIMATIONS")
    }
}

// MARK: - Async Test Helpers

extension Task where Failure == Error {
    /// Execute task and wait for result in tests
    @discardableResult
    static func testSync(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> Success
    ) throws -> Success {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<Success, Error>?
        
        Task {
            do {
                let value = try await operation()
                result = .success(value)
            } catch {
                result = .failure(error)
            }
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + timeout)
        
        guard let finalResult = result else {
            throw TestError.timeout
        }
        
        switch finalResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}

enum TestError: Error {
    case timeout
    case unexpectedNil
    case invalidState
}

// MARK: - SwiftUI Test Helpers

extension View {
    func testable() -> some View {
        self
            .environment(\.isTestEnvironment, true)
            .animation(nil) // Disable animations in tests
    }
}

private struct IsTestEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isTestEnvironment: Bool {
        get { self[IsTestEnvironmentKey.self] }
        set { self[IsTestEnvironmentKey.self] = newValue }
    }
}

// MARK: - Matcher Helpers

func XCTAssertEqualWithAccuracy<T: FloatingPoint>(
    _ expression1: T,
    _ expression2: T,
    accuracy: T,
    file: StaticString = #file,
    line: UInt = #line
) {
    let difference = abs(expression1 - expression2)
    XCTAssertLessThanOrEqual(
        difference,
        accuracy,
        "Values differ by \(difference), which exceeds accuracy \(accuracy)",
        file: file,
        line: line
    )
}

func XCTAssertThrowsSpecificError<T, E: Error & Equatable>(
    _ expression: @autoclosure () async throws -> T,
    _ expectedError: E,
    file: StaticString = #file,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected error \(expectedError) but no error was thrown", file: file, line: line)
    } catch let error as E {
        XCTAssertEqual(error, expectedError, file: file, line: line)
    } catch {
        XCTFail("Expected error \(expectedError) but got \(error)", file: file, line: line)
    }
}

// MARK: - Performance Test Helpers

extension XCTestCase {
    func measureAsync(
        timeout: TimeInterval = 10.0,
        block: @escaping () async throws -> Void
    ) {
        measure {
            let expectation = expectation(description: "Performance test")
            
            Task {
                do {
                    try await block()
                    expectation.fulfill()
                } catch {
                    XCTFail("Performance test failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: timeout)
        }
    }
}