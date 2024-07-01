//
//  usdzuploaderTests.swift
//  usdzuploaderTests
//
//  Created by WorkMerkDev on 6/19/24.
//

@testable import usdzuploader
import XCTest

final class usdzuploaderUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false

        // UI tests must launch the application that they test.
    }
    
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGenerate3DModel() throws {
        let app = XCUIApplication()

        
        // Ensure we're on the main screen
        XCTAssertTrue(app.otherElements["MainView"].exists)
        
        // Tap on the prompt TextEditor
        let promptTextEditor = app.textViews["promptTextEditor"]
        XCTAssertTrue(promptTextEditor.exists)
        promptTextEditor.tap()
        
        // Type a random prompt
        let randomPrompt = "Generate a 3D model of a futuristic car"
        promptTextEditor.typeText(randomPrompt)
        
        // Tap on the generate button
        let generateButton = app.buttons["generateButton"]
        XCTAssertTrue(generateButton.exists)
        generateButton.tap()
        
        // Wait for the progress view to appear
        let progressView = app.progressIndicators["progressView"]
        XCTAssertTrue(progressView.waitForExistence(timeout: 10))
        
        // Wait for the model URL to be set and check if the save button appears
        let saveButton = app.buttons["saveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 30))
    }
    
    func testGenerate3DModelAPIFailure() throws {
        let app = XCUIApplication()
        
        // Ensure we're on the main screen
        XCTAssertTrue(app.otherElements["MainView"].exists)
        
        // Tap on the prompt TextEditor
        let promptTextEditor = app.textViews["promptTextEditor"]
        XCTAssertTrue(promptTextEditor.exists)
        promptTextEditor.tap()
        
        // Type a random prompt
        let randomPrompt = "Generate a 3D model of a futuristic car"
        promptTextEditor.typeText(randomPrompt)
        
        // Simulate API failure
        // You may need to set a specific environment variable or condition in your app to simulate this
        
        // Tap on the generate button
        let generateButton = app.buttons["generateButton"]
        XCTAssertTrue(generateButton.exists)
        generateButton.tap()
        
        // Wait for the alert to appear
        let alert = app.alerts["Error"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
    }
}




