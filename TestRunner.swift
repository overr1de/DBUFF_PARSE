import Foundation
import SwiftUI

// Simple test runner for debugging TextField issues
@MainActor
class TestRunner {
    static func runTextFieldTests() {
        print("🧪 Running TextField Debug Tests...")
        
        let viewModel = DotabuffViewModel()
        
        // Test 1: Initial state
        print("Test 1 - Initial state:")
        print("  userID: '\(viewModel.userID)'")
        print("  isEmpty: \(viewModel.userID.isEmpty)")
        
        // Test 2: Setting value
        print("\nTest 2 - Setting value:")
        viewModel.userID = "44764606"
        print("  userID after setting: '\(viewModel.userID)'")
        print("  isEmpty: \(viewModel.userID.isEmpty)")
        
        // Test 3: Clearing value
        print("\nTest 3 - Clearing value:")
        viewModel.userID = ""
        print("  userID after clearing: '\(viewModel.userID)'")
        print("  isEmpty: \(viewModel.userID.isEmpty)")
        
        // Test 4: Character by character
        print("\nTest 4 - Character by character:")
        let testInput = "123456"
        for (index, char) in testInput.enumerated() {
            let partial = String(testInput.prefix(index + 1))
            viewModel.userID = partial
            print("  Step \(index + 1): '\(viewModel.userID)'")
        }
        
        // Test 5: Special characters
        print("\nTest 5 - Special characters:")
        let specialInputs = ["abc123", "test-user_123", "  spaces  ", "🎮emoji🎯"]
        for input in specialInputs {
            viewModel.userID = input
            print("  Input '\(input)' -> stored: '\(viewModel.userID)'")
        }
        
        print("\n✅ TextField Debug Tests Complete")
    }
    
    static func testBinding() {
        print("🔗 Testing SwiftUI Binding...")
        
        let viewModel = DotabuffViewModel()
        
        // Create a binding
        let binding = Binding<String>(
            get: { viewModel.userID },
            set: { viewModel.userID = $0 }
        )
        
        print("Initial binding value: '\(binding.wrappedValue)'")
        
        // Test setting through binding
        binding.wrappedValue = "test123"
        print("After setting through binding: '\(viewModel.userID)'")
        print("Binding value: '\(binding.wrappedValue)'")
        
        // Test setting through viewModel
        viewModel.userID = "direct456"
        print("After setting directly: '\(viewModel.userID)'")
        print("Binding value: '\(binding.wrappedValue)'")
        
        print("✅ Binding Test Complete")
    }
}