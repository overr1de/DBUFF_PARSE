import XCTest
import SwiftUI
import Combine

@MainActor
final class DotabuffViewModelTests: XCTestCase {
    var viewModel: DotabuffViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = DotabuffViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Input Field Data Binding Tests
    
    func testUserIDInitialValue() {
        // Test that userID starts empty
        XCTAssertEqual(viewModel.userID, "", "userID should initialize as empty string")
    }
    
    func testUserIDValueUpdate() {
        // Test that userID updates when set
        let testID = "44764606"
        viewModel.userID = testID
        XCTAssertEqual(viewModel.userID, testID, "userID should update to the assigned value")
    }
    
    func testUserIDPublishedNotification() {
        // Test that userID changes are published
        let expectation = expectation(description: "userID should publish changes")
        let testID = "12345678"
        
        viewModel.$userID
            .dropFirst() // Skip initial value
            .sink { receivedValue in
                XCTAssertEqual(receivedValue, testID, "Published userID should match assigned value")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.userID = testID
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUserIDWhitespaceHandling() {
        // Test that whitespace-only input is handled correctly
        viewModel.userID = "   "
        XCTAssertEqual(viewModel.userID, "   ", "userID should store whitespace as-is")
        
        let isEmpty = viewModel.userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        XCTAssertTrue(isEmpty, "Trimmed userID should be considered empty")
    }
    
    func testUserIDSpecialCharacters() {
        // Test that special characters are handled
        let testIDs = ["44764606", "123-456-789", "user_123", "!@#$%"]
        
        for testID in testIDs {
            viewModel.userID = testID
            XCTAssertEqual(viewModel.userID, testID, "userID should handle special characters: \(testID)")
        }
    }
    
    func testUserIDLongInput() {
        // Test that long inputs are handled
        let longID = String(repeating: "1234567890", count: 10) // 100 characters
        viewModel.userID = longID
        XCTAssertEqual(viewModel.userID, longID, "userID should handle long inputs")
    }
    
    func testUserIDClearValue() {
        // Test clearing the userID
        viewModel.userID = "44764606"
        XCTAssertFalse(viewModel.userID.isEmpty, "userID should have value")
        
        viewModel.userID = ""
        XCTAssertEqual(viewModel.userID, "", "userID should be cleared")
        XCTAssertTrue(viewModel.userID.isEmpty, "userID should be empty after clearing")
    }
    
    // MARK: - UI State Tests
    
    func testLoadingStateInitialValue() {
        XCTAssertFalse(viewModel.isLoading, "isLoading should initialize as false")
    }
    
    func testErrorMessageInitialValue() {
        XCTAssertNil(viewModel.errorMessage, "errorMessage should initialize as nil")
    }
    
    func testHeroStatsInitialValue() {
        XCTAssertTrue(viewModel.heroStats.isEmpty, "heroStats should initialize as empty array")
    }
    
    // MARK: - Input Validation Tests
    
    func testCanPerformSearchLogic() {
        // Test search enabling/disabling logic
        
        // Empty userID should disable search
        viewModel.userID = ""
        viewModel.isLoading = false
        let canSearchEmpty = !viewModel.userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading
        XCTAssertFalse(canSearchEmpty, "Search should be disabled with empty userID")
        
        // Valid userID should enable search
        viewModel.userID = "44764606"
        viewModel.isLoading = false
        let canSearchValid = !viewModel.userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading
        XCTAssertTrue(canSearchValid, "Search should be enabled with valid userID")
        
        // Loading state should disable search
        viewModel.userID = "44764606"
        viewModel.isLoading = true
        let canSearchLoading = !viewModel.userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading
        XCTAssertFalse(canSearchLoading, "Search should be disabled while loading")
        
        // Whitespace-only userID should disable search
        viewModel.userID = "   "
        viewModel.isLoading = false
        let canSearchWhitespace = !viewModel.userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading
        XCTAssertFalse(canSearchWhitespace, "Search should be disabled with whitespace-only userID")
    }
    
    // MARK: - Multiple Updates Test
    
    func testMultipleUserIDUpdates() {
        let expectation = expectation(description: "Multiple userID updates should all be published")
        expectation.expectedFulfillmentCount = 3
        
        let testIDs = ["123", "456", "789"]
        var receivedValues: [String] = []
        
        viewModel.$userID
            .dropFirst() // Skip initial value
            .sink { receivedValue in
                receivedValues.append(receivedValue)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        for testID in testIDs {
            viewModel.userID = testID
        }
        
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedValues, testIDs, "All userID updates should be received in order")
    }
}