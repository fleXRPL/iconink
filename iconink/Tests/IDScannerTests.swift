import XCTest
@testable import iconink

final class IDScannerTests: XCTestCase {
    func testImageQualityAssessment() {
        // Create a test image of good quality
        let goodQualityImage = createTestImage(size: CGSize(width: 1000, height: 600), color: .white)
        
        // Create a test image of poor quality (small)
        let poorQualityImage = createTestImage(size: CGSize(width: 200, height: 100), color: .white)
        
        // Test private method using reflection
        let qualityGood = invokePrivateMethod(
            cls: IDScanner.self, 
            selector: "assessImageQuality:", 
            args: [goodQualityImage]
        ) as? Int
        
        let qualityPoor = invokePrivateMethod(
            cls: IDScanner.self, 
            selector: "assessImageQuality:", 
            args: [poorQualityImage]
        ) as? Int
        
        // ImageQuality.good should be 1, ImageQuality.poor should be 0
        XCTAssertEqual(qualityGood, 1, "Expected good quality image to be assessed as good")
        XCTAssertEqual(qualityPoor, 0, "Expected poor quality image to be assessed as poor")
    }
    
    func testExtractedInfoValidation() {
        // Valid information with name and ID number
        let validInfo1: [String: String] = [
            "name": "John Smith",
            "idNumber": "AB123456"
        ]
        
        // Valid information with name, DOB, and address
        let validInfo2: [String: String] = [
            "name": "Jane Doe",
            "dob": "01/01/1990",
            "address": "123 Main St, Anytown, CA 12345"
        ]
        
        // Invalid information (missing required fields)
        let invalidInfo1: [String: String] = [
            "name": "John"  // Single name, no other identifying information
        ]
        
        let invalidInfo2: [String: String] = [
            "idNumber": "12345" // ID number but no name or other identifying info
        ]
        
        // Test private validation method using reflection
        let isValid1 = invokePrivateMethod(
            cls: IDScanner.self, 
            selector: "validateExtractedInfo:", 
            args: [validInfo1]
        ) as? Bool
        
        let isValid2 = invokePrivateMethod(
            cls: IDScanner.self, 
            selector: "validateExtractedInfo:", 
            args: [validInfo2]
        ) as? Bool
        
        let isInvalid1 = invokePrivateMethod(
            cls: IDScanner.self, 
            selector: "validateExtractedInfo:", 
            args: [invalidInfo1]
        ) as? Bool
        
        let isInvalid2 = invokePrivateMethod(
            cls: IDScanner.self, 
            selector: "validateExtractedInfo:", 
            args: [invalidInfo2]
        ) as? Bool
        
        XCTAssertTrue(isValid1 ?? false, "Expected info with name and ID to be valid")
        XCTAssertTrue(isValid2 ?? false, "Expected info with name, DOB, and address to be valid")
        XCTAssertFalse(isInvalid1 ?? true, "Expected info with just first name to be invalid")
        XCTAssertFalse(isInvalid2 ?? true, "Expected info with just ID number to be invalid")
    }
    
    func testParseIDInformation() {
        // Test text lines that contain ID information
        let testTextLines = [
            "DRIVER LICENSE",
            "NAME: JOHN DOE",
            "DOB: 01/15/1985",
            "ID NO: AB123456",
            "ADDRESS: 123 MAIN ST",
            "ANYTOWN, CA 12345",
            "EXP: 01/15/2025",
            "EMAIL: john.doe@example.com",
            "PHONE: (555) 123-4567"
        ]
        
        // Test the parsing method
        let result = invokePrivateMethod(
            cls: IDScanner.self, 
            selector: "parseIDInformation:", 
            args: [testTextLines]
        ) as? [String: String]
        
        // Verify the extracted information
        XCTAssertNotNil(result, "Failed to parse ID information")
        XCTAssertEqual(result?["name"], "John Doe", "Failed to correctly parse name")
        XCTAssertEqual(result?["dob"], "01/15/1985", "Failed to correctly parse date of birth")
        XCTAssertEqual(result?["idNumber"], "AB123456", "Failed to correctly parse ID number")
        XCTAssertEqual(result?["address"], "123 MAIN ST, ANYTOWN, CA 12345", "Failed to correctly parse address")
        XCTAssertEqual(result?["expiry"], "01/15/2025", "Failed to correctly parse expiry date")
        XCTAssertEqual(result?["email"], "john.doe@example.com", "Failed to correctly parse email")
        XCTAssertEqual(result?["phone"], "(555) 123-4567", "Failed to correctly parse phone number")
    }
    
    func testScanIDResult() {
        // Test success case
        let successInfo: [String: String] = ["name": "John Doe", "idNumber": "AB123456"]
        let successResult = IDScanResult.success(info: successInfo)
        
        // Test failure case
        let failureResult = IDScanResult.failure(error: "Test error", errorType: .noTextFound)
        
        // Check properties
        XCTAssertTrue(successResult.isSuccess, "Success result should return true for isSuccess")
        XCTAssertFalse(failureResult.isSuccess, "Failure result should return false for isSuccess")
        
        XCTAssertEqual(successResult.extractedInfo, successInfo, "Should return the provided info dictionary")
        XCTAssertTrue(failureResult.extractedInfo.isEmpty, "Should return empty dictionary for failure")
        
        XCTAssertNil(successResult.errorMessage, "Success result should have nil error message")
        XCTAssertEqual(failureResult.errorMessage, "Test error", "Should return provided error message")
        
        XCTAssertNil(successResult.errorType, "Success result should have nil error type")
        XCTAssertEqual(failureResult.errorType, .noTextFound, "Should return provided error type")
    }
    
    // MARK: - Helper Methods
    
    /// Creates a test UIImage with the specified size and color
    private func createTestImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add some text to simulate ID content
            let text = "SAMPLE ID"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            
            let textRect = CGRect(x: 20, y: 20, width: size.width - 40, height: 50)
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        return image
    }
    
    /// Helper to invoke private methods using reflection
    private func invokePrivateMethod(cls: AnyClass, selector: String, args: [Any]) -> Any? {
        // Convert selector string to Selector
        let selectorObj = NSSelectorFromString(selector)
        
        // Check if class responds to selector
        guard cls.responds(to: selectorObj) else {
            XCTFail("Class \(cls) does not respond to selector \(selector)")
            return nil
        }
        
        // Get method implementation
        let methodIMP = class_getMethodImplementation(cls, selectorObj)
        
        // Create function pointer of appropriate type
        let method = unsafeBitCast(methodIMP, to: (@convention(c) (AnyClass, Selector, Any) -> Any).self)
        
        // Call method with first argument
        return method(cls, selectorObj, args[0])
    }
} 
