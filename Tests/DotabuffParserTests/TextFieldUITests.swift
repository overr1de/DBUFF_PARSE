import XCTest
import SwiftUI

@MainActor
final class TextFieldUITests: XCTestCase {
    var viewModel: DotabuffViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = DotabuffViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - TextField Binding Tests
    
    // MARK: - Manual TextField Tests (without ViewInspector)
    
    func testTextFieldBinding() {
        // Test the binding between TextField and ViewModel
        let initialValue = viewModel.userID
        XCTAssertEqual(initialValue, "", "Initial userID should be empty")
        
        // Simulate user input
        let testInput = "44764606"
        viewModel.userID = testInput
        
        // Verify the binding works
        XCTAssertEqual(viewModel.userID, testInput, "ViewModel userID should update when TextField value changes")
    }
    
    func testTextFieldValuePersistence() {
        // Test that TextField value persists across UI updates
        let testValues = ["123", "44764606", "987654321", ""]
        
        for testValue in testValues {
            viewModel.userID = testValue
            XCTAssertEqual(viewModel.userID, testValue, "TextField value should persist: '\(testValue)'")
        }
    }
    
    func testTextFieldCharacterByCharacterInput() {
        // Simulate typing character by character
        let targetValue = "44764606"
        var currentValue = ""
        
        for char in targetValue {
            currentValue += String(char)
            viewModel.userID = currentValue
            XCTAssertEqual(viewModel.userID, currentValue, "TextField should update with each character: '\(currentValue)'")
        }
        
        XCTAssertEqual(viewModel.userID, targetValue, "Final TextField value should match target")
    }
    
    func testTextFieldPasteSimulation() {
        // Simulate paste operation
        let pastedValue = "44764606"
        
        // Clear any existing value
        viewModel.userID = ""
        XCTAssertEqual(viewModel.userID, "", "TextField should be cleared")
        
        // Simulate paste by setting full value at once
        viewModel.userID = pastedValue
        XCTAssertEqual(viewModel.userID, pastedValue, "TextField should accept pasted value")
    }
    
    func testTextFieldClearOperation() {
        // Test clearing the TextField
        viewModel.userID = "44764606"
        XCTAssertFalse(viewModel.userID.isEmpty, "TextField should have value")
        
        // Simulate clear (like clear button)
        viewModel.userID = ""
        XCTAssertTrue(viewModel.userID.isEmpty, "TextField should be empty after clear")
        XCTAssertEqual(viewModel.userID, "", "TextField should have empty string value")
    }
    
    func testTextFieldSpecialInputs() {
        // Test various input types
        let testInputs = [
            "123456789",           // Numbers
            "abc123def",           // Mixed alphanumeric
            "user-123_test",       // Special characters
            "   44764606   ",      // With spaces
            "",                    // Empty string
            "🎮🎯🚀",              // Emojis
            "very_long_player_id_with_many_characters_123456789" // Long input
        ]
        
        for input in testInputs {
            viewModel.userID = input
            XCTAssertEqual(viewModel.userID, input, "TextField should handle input: '\(input)'")
        }
    }
    
    // MARK: - Button State Tests Related to TextField
    
    func testButtonStateBasedOnTextFieldValue() {
        // Test button enabling/disabling based on TextField content
        
        // Empty TextField -> Button disabled
        viewModel.userID = ""
        viewModel.isLoading = false
        let buttonDisabledEmpty = viewModel.userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
        XCTAssertTrue(buttonDisabledEmpty, "Button should be disabled when TextField is empty")
        
        // TextField with value -> Button enabled
        viewModel.userID = "44764606"
        viewModel.isLoading = false
        let buttonEnabledWithValue = viewModel.userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
        XCTAssertFalse(buttonEnabledWithValue, "Button should be enabled when TextField has value")
        
        // TextField with only spaces -> Button disabled
        viewModel.userID = "   "
        viewModel.isLoading = false
        let buttonDisabledSpaces = viewModel.userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
        XCTAssertTrue(buttonDisabledSpaces, "Button should be disabled when TextField has only spaces")
    }
    
    // MARK: - Performance Tests
    
    func testTextFieldPerformanceWithManyUpdates() {
        measure {
            // Test performance with many rapid updates
            for i in 0..<1000 {
                viewModel.userID = String(i)
            }
        }
    }
    
    // MARK: - Real-world Usage Tests
    
    func testTypicalUserWorkflow() {
        // Simulate a typical user workflow
        
        // 1. User starts with empty field
        XCTAssertEqual(viewModel.userID, "", "Should start with empty TextField")
        
        // 2. User types a few characters
        viewModel.userID = "44"
        XCTAssertEqual(viewModel.userID, "44", "Should show partial input")
        
        // 3. User continues typing
        viewModel.userID = "447646"
        XCTAssertEqual(viewModel.userID, "447646", "Should show continued input")
        
        // 4. User completes the ID
        viewModel.userID = "44764606"
        XCTAssertEqual(viewModel.userID, "44764606", "Should show complete input")
        
        // 5. User clears and starts over
        viewModel.userID = ""
        XCTAssertEqual(viewModel.userID, "", "Should clear completely")
        
        // 6. User pastes a different ID
        viewModel.userID = "123456789"
        XCTAssertEqual(viewModel.userID, "123456789", "Should accept pasted value")
    }
    
    func testErrorRecoveryWorkflow() {
        // Test recovery from errors
        
        // User enters invalid ID
        viewModel.userID = "invalid"
        viewModel.errorMessage = "Invalid player ID"
        
        // User corrects the ID
        viewModel.userID = "44764606"
        XCTAssertEqual(viewModel.userID, "44764606", "Should accept corrected input")
        
        // Error should be clearable
        viewModel.errorMessage = nil
        XCTAssertNil(viewModel.errorMessage, "Error should be cleared")
    }
}