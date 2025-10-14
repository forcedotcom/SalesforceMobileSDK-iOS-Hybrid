/*
 Copyright (c) 2025-present, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import XCTest
import Foundation
@testable import SalesforceHybridSDK
import SalesforceSDKCore

/**
 * Test suite for SalesforceWebViewCookieManager class.
 */
class SalesforceWebViewCookieManagerTestSuite: XCTestCase {
    
    private var cookieManager: SalesforceWebViewCookieManager!
    private var capturedWarnings: [String] = []
    
    override func setUp() {
        super.setUp()
        cookieManager = SalesforceWebViewCookieManager()
        capturedWarnings = []
    }
    
    override func tearDown() {
        cookieManager = nil
        capturedWarnings = []
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func captureWarnings(_ message: String) {
        capturedWarnings.append(message)
    }
    
    private func assertNoWarnings() {
        XCTAssertTrue(capturedWarnings.isEmpty, "Expected no warnings, but got: \(capturedWarnings)")
    }
    
    private func assertWarningContains(_ substring: String) {
        let containsSubstring = capturedWarnings.contains { warning in
            return warning.contains(substring)
        }
        XCTAssertTrue(containsSubstring, "Expected warning containing '\(substring)', but got warnings: \(capturedWarnings)")
    }
    
    private func assertWarningDoesNotContain(_ substring: String) {
        let containsSubstring = capturedWarnings.contains { warning in
            return warning.contains(substring)
        }
        XCTAssertFalse(containsSubstring, "Expected no warning containing '\(substring)', but got warnings: \(capturedWarnings)")
    }
    
    private func assertWarningCount(_ expectedCount: Int) {
        XCTAssertEqual(capturedWarnings.count, expectedCount, "Expected \(expectedCount) warnings, but got \(capturedWarnings.count): \(capturedWarnings)")
    }
    
    // MARK: - Test Cases for inspectScopes Method
    
    /**
     * Test inspectScopes with full scope - should not warn about any missing scopes.
     */
    func testInspectScopesWithFullScope() {
        cookieManager.inspectScopes(["full"], warn: captureWarnings)
        
        XCTAssertTrue(capturedWarnings.isEmpty, 
                     "Should not warn about any missing scopes when 'full' scope is present")
    }
    
    /**
     * Test inspectScopes with all individual scopes - should not warn about any missing scopes.
     */
    func testInspectScopesWithAllIndividualScopes() {
        cookieManager.inspectScopes(["web", "visualforce", "lightning", "content"], warn: captureWarnings)
        
        XCTAssertTrue(capturedWarnings.isEmpty, 
                     "Should not warn about any missing scopes when all individual scopes are present")
    }
    
    /**
     * Test inspectScopes with web scope - should not warn about web or visualforce.
     */
    func testInspectScopesWithWebScope() {
        cookieManager.inspectScopes(["web", "lightning", "content"], warn: captureWarnings)
        
        assertWarningDoesNotContain("web")
        assertWarningDoesNotContain("visualforce")
        assertWarningDoesNotContain("lightning")
        assertWarningDoesNotContain("content")
        assertNoWarnings()
    }
    
    /**
     * Test inspectScopes with visualforce scope but no web scope - should warn about web.
     */
    func testInspectScopesWithVisualforceButNoWebScope() {
        cookieManager.inspectScopes(["visualforce", "lightning", "content"], warn: captureWarnings)
        
        XCTAssertTrue(capturedWarnings.contains { $0.contains("Missing web scope") },
                     "Should warn about missing web scope")
        assertWarningDoesNotContain("visualforce")
    }
    
    /**
     * Test inspectScopes with missing web scope - should warn about web and visualforce.
     */
    func testInspectScopesWithMissingWebScope() {
        cookieManager.inspectScopes(["lightning", "content"], warn: captureWarnings)
        
        XCTAssertTrue(capturedWarnings.contains { $0.contains("Missing web scope") },
                     "Should warn about missing web scope")
        XCTAssertTrue(capturedWarnings.contains { $0.contains("Missing visualforce scope") },
                     "Should warn about missing visualforce scope")
    }
    
    /**
     * Test inspectScopes with missing lightning scope - should warn about lightning.
     */
    func testInspectScopesWithMissingLightningScope() {
        cookieManager.inspectScopes(["web", "content"], warn: captureWarnings)
        
        XCTAssertTrue(capturedWarnings.contains { $0.contains("Missing lightning scope") },
                     "Should warn about missing lightning scope")
    }
    
    /**
     * Test inspectScopes with missing content scope - should warn about content.
     */
    func testInspectScopesWithMissingContentScope() {
        cookieManager.inspectScopes(["web", "lightning"], warn: captureWarnings)
        
        XCTAssertTrue(capturedWarnings.contains { $0.contains("Missing content scope") },
                     "Should warn about missing content scope")
    }
    
}
