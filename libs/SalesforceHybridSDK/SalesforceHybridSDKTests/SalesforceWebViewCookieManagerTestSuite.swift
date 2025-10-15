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
    
    // MARK: - setCookies Method Tests
    
    /**
     * Test setCookies with complete user account - should call setCookieValue for all domains.
     */
    @MainActor func testSetCookiesWithCompleteUserAccount() {
        guard let userAccount = createTestUserAccount() else {
            XCTFail("Failed to create test user account")
            return
        }
        
        var setCookieValueCalls: [CookieCall] = []
        var completionCalled = false
        
        let setCookieValueLambda: (String, String?, Bool, String?, String?) -> Void = { cookieType, domain, setDomain, name, value in
            setCookieValueCalls.append(CookieCall(cookieType: cookieType, domain: domain, setDomain: setDomain, name: name, value: value))
        }
        
        let expectation = XCTestExpectation(description: "setCookies completion")
        
        cookieManager.setCookies(
            userAccount: userAccount,
            setCookieValue: setCookieValueLambda
        ) {
            completionCalled = true
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify completion was called
        XCTAssertTrue(completionCalled, "Completion should be called once")
        
        // Verify all expected cookie calls were made (setDomain should be false since no community URL)
        let expectedCalls = [
            CookieCall(cookieType: "sid for main", domain: "test.salesforce.com", setDomain: false, name: "sid", value: "test_auth_token"),
            CookieCall(cookieType: "clientSrc", domain: "test.salesforce.com", setDomain: false, name: "clientSrc", value: "test_client_src"),
            CookieCall(cookieType: "sid_Client", domain: "test.salesforce.com", setDomain: false, name: "sid_Client", value: "test_sid_client"),
            CookieCall(cookieType: "oid", domain: "test.salesforce.com", setDomain: false, name: "oid", value: "test_org_id"),
            CookieCall(cookieType: "eikoocnekotMob", domain: "test.salesforce.com", setDomain: false, name: "eikoocnekotMob", value: "test_csrf_token"),
            CookieCall(cookieType: "sid for lightning", domain: "lightning.test.salesforce.com", setDomain: false, name: "sid", value: "test_lightning_sid"),
            CookieCall(cookieType: "eikoocnekotMob", domain: "lightning.test.salesforce.com", setDomain: false, name: "eikoocnekotMob", value: "test_csrf_token"),
            CookieCall(cookieType: "sid for content", domain: "content.test.salesforce.com", setDomain: false, name: "sid", value: "test_content_sid"),
            CookieCall(cookieType: "sid for vf", domain: "vf.test.salesforce.com", setDomain: false, name: "sid", value: "test_vf_sid"),
            CookieCall(cookieType: "clientSrc", domain: "vf.test.salesforce.com", setDomain: false, name: "clientSrc", value: "test_client_src"),
            CookieCall(cookieType: "sid_Client", domain: "vf.test.salesforce.com", setDomain: false, name: "sid_Client", value: "test_sid_client"),
            CookieCall(cookieType: "oid", domain: "vf.test.salesforce.com", setDomain: false, name: "oid", value: "test_org_id")
        ]
        
        XCTAssertEqual(setCookieValueCalls.count, expectedCalls.count,
                      "Should make correct number of setCookieValue calls")
        
        // Verify each expected call
        for expectedCall in expectedCalls {
            XCTAssertTrue(setCookieValueCalls.contains(expectedCall),
                         "Should contain call: \(expectedCall)")
        }
    }
    
    /**
     * Test setCookies with JWT token format - should use parentSid instead of authToken.
     */
    @MainActor func testSetCookiesWithJWTTokenFormat() {
        guard let jwtUserAccount = createTestUserAccountWithJWT() else {
            XCTFail("Failed to create JWT test user account")
            return
        }
        
        var setCookieValueCalls: [CookieCall] = []
        
        let setCookieValueLambda: (String, String?, Bool, String?, String?) -> Void = { cookieType, domain, setDomain, name, value in
            setCookieValueCalls.append(CookieCall(cookieType: cookieType, domain: domain, setDomain: setDomain, name: name, value: value))
        }
        
        let expectation = XCTestExpectation(description: "setCookies completion")
        
        cookieManager.setCookies(
            userAccount: jwtUserAccount,
            setCookieValue: setCookieValueLambda
        ) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Find the main SID call
        let mainSidCall = setCookieValueCalls.first { $0.cookieType == "sid for main" }
        XCTAssertNotNil(mainSidCall, "Should have main SID call")
        XCTAssertEqual(mainSidCall?.value, "test_parent_sid", 
                      "Should use parentSid for JWT token format")
    }

   /**
     * Test setCookies with community URL - should set domain flag to true.
     */
    @MainActor func testSetCookiesWithCommunityUrl() {
        guard let communityUserAccount = createTestUserAccountWithCommunity() else {
            XCTFail("Failed to create community test user account")
            return
        }
        
        var setCookieValueCalls: [CookieCall] = []
        
        let setCookieValueLambda: (String, String?, Bool, String?, String?) -> Void = { cookieType, domain, setDomain, name, value in
            setCookieValueCalls.append(CookieCall(cookieType: cookieType, domain: domain, setDomain: setDomain, name: name, value: value))
        }
        
        let expectation = XCTestExpectation(description: "setCookies completion")
        
        cookieManager.setCookies(
            userAccount: communityUserAccount,
            setCookieValue: setCookieValueLambda
        ) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify that setDomain is true for all calls when community URL is present
        XCTAssertGreaterThan(setCookieValueCalls.count, 0, "Should have made some cookie calls")
        
        let allCallsHaveSetDomainTrue = setCookieValueCalls.allSatisfy { $0.setDomain }
        XCTAssertTrue(allCallsHaveSetDomainTrue,
                     "All calls should have setDomain=true when community URL is present")
    }        
    
    // MARK: - Helper Data Structures
    
    /**
     * Helper data structure for tracking cookie calls.
     */
    private struct CookieCall: Equatable {
        let cookieType: String
        let domain: String?
        let setDomain: Bool
        let name: String?
        let value: String?
        
        static func == (lhs: CookieCall, rhs: CookieCall) -> Bool {
            return lhs.cookieType == rhs.cookieType &&
                   lhs.domain == rhs.domain &&
                   lhs.setDomain == rhs.setDomain &&
                   lhs.name == rhs.name &&
                   lhs.value == rhs.value
        }
    }
    
    // MARK: - Helper Methods for User Account Creation
    
    /**
     * Helper method to create a test UserAccount with all required fields.
     * Based on Android createTestUserAccount() helper.
     */
    private func createTestUserAccount() -> UserAccount? {
        guard let credentials = OAuthCredentials(identifier: "test-identifier", clientId: "test-client-id", encrypted: false) else {
            return nil
        }
        
        // Use updateCredentials method to set all the properties
        let params: [String: String] = [
            "access_token": "test_auth_token",
            "refresh_token": "test_refresh_token",
            "instance_url": "https://test.salesforce.com",
            "api_instance_url": "https://test.salesforce.com", 
            "id": "https://test.salesforce.com/id/test_org_id/test_user_id",
            "scope": "web lightning content",
            "lightning_domain": "lightning.test.salesforce.com",
            "lightning_sid": "test_lightning_sid",
            "visualforce_domain": "vf.test.salesforce.com",
            "visualforce_sid": "test_vf_sid",
            "content_domain": "content.test.salesforce.com",
            "content_sid": "test_content_sid",
            "csrf_token": "test_csrf_token",
            "cookie-clientSrc": "test_client_src",
            "cookie-sid_Client": "test_sid_client",
            "sidCookieName": "sid",
            "parent_sid": "test_parent_sid",
            "token_format": "access_token"
        ]
        
        credentials.update(params)
        let userAccount = UserAccount(credentials: credentials)
        
        return userAccount
    }
    
    /**
     * Helper method to create a test UserAccount with JWT token format.
     * Based on Android createTestUserAccountWithJWT() helper.
     */
    private func createTestUserAccountWithJWT() -> UserAccount? {
        guard let credentials = OAuthCredentials(identifier: "test-identifier-jwt", clientId: "test-client-id", encrypted: false) else {
            return nil
        }
        
        // Use updateCredentials method with JWT token format
        let params: [String: String] = [
            "access_token": "test_auth_token",
            "refresh_token": "test_refresh_token",
            "instance_url": "https://test.salesforce.com",
            "api_instance_url": "https://test.salesforce.com",
            "id": "https://test.salesforce.com/id/test_org_id/test_user_id",
            "scope": "web lightning content",
            "lightning_domain": "lightning.test.salesforce.com",
            "lightning_sid": "test_lightning_sid",
            "visualforce_domain": "vf.test.salesforce.com",
            "visualforce_sid": "test_vf_sid",
            "content_domain": "content.test.salesforce.com",
            "content_sid": "test_content_sid",
            "csrf_token": "test_csrf_token",
            "cookie-clientSrc": "test_client_src",
            "cookie-sid_Client": "test_sid_client",
            "sidCookieName": "sid",
            "parent_sid": "test_parent_sid",
            "token_format": "jwt"  // This is the key difference - JWT format
        ]
        
        credentials.update(params)
        let userAccount = UserAccount(credentials: credentials)
        
        return userAccount
    }
    
    /**
     * Helper method to create a test UserAccount with community URL.
     */
    private func createTestUserAccountWithCommunity() -> UserAccount? {
        guard let credentials = OAuthCredentials(identifier: "test-identifier-community", clientId: "test-client-id", encrypted: false) else {
            return nil
        }
        
        // Use updateCredentials method with community URL
        let params: [String: String] = [
            "access_token": "test_auth_token",
            "refresh_token": "test_refresh_token",
            "instance_url": "https://test.salesforce.com",
            "api_instance_url": "https://test.salesforce.com",
            "id": "https://test.salesforce.com/id/test_org_id/test_user_id",
            "scope": "web lightning content",
            "lightning_domain": "lightning.test.salesforce.com",
            "lightning_sid": "test_lightning_sid",
            "visualforce_domain": "vf.test.salesforce.com",
            "visualforce_sid": "test_vf_sid",
            "content_domain": "content.test.salesforce.com",
            "content_sid": "test_content_sid",
            "csrf_token": "test_csrf_token",
            "cookie-clientSrc": "test_client_src",
            "cookie-sid_Client": "test_sid_client",
            "sidCookieName": "sid",
            "parent_sid": "test_parent_sid",
            "token_format": "access_token",
            "sfdc_community_url": "https://community.salesforce.com"  // Add community URL
        ]
        
        credentials.update(params)
        let userAccount = UserAccount(credentials: credentials)
        
        return userAccount
    }   
 
}
