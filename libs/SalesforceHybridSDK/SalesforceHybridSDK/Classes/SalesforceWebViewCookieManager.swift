/*
 SalesforceWebViewCookieManager.swift
 SalesforceHybridSDK
 
 Created by Wolfgang Mathurin on 11/06/24.
 
 Copyright (c) 2024-present, salesforce.com, inc. All rights reserved.
 
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

import Foundation
import WebKit

@objc(SFSDKSalesforceWebViewCookieManager)
class SalesforceWebViewCookieManager: NSObject {
    @MainActor @objc func setCookies(userAccount: UserAccount, completion: @escaping () -> Void) {
        let creds = userAccount.credentials
        SFSDKHybridLogger.i(Self.self, message: "[\(Self.self) \(#function)]: setting cookies for \(String(describing: creds.userId)).")
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        let instanceUrl = creds.instanceUrl
        let lightningDomain = creds.lightningDomain
        let lightningSid = creds.lightningSid
        let contentDomain = creds.contentDomain
        let contentSid = creds.contentSid
        let mainSid = creds.tokenFormat == "jwt" ? creds.parentSid : creds.accessToken
        let vfDomain = creds.vfDomain
        let vfSid = creds.vfSid
        let clientSrc = creds.cookieClientSrc
        let sidClient = creds.cookieSidClient
        let sidCookieName = creds.sidCookieName
        let csrfToken = creds.csrfToken
        let orgId = userAccount.accountIdentity.orgId
        let mainDomain = getDomainFromUrl(instanceUrl)
        
        // Main domain cookies
        setCookieValue(cookieStore: cookieStore, cookieType: "sid for main", domain: mainDomain, name: sidCookieName, value: mainSid)
        setCookieValue(cookieStore: cookieStore, cookieType: Self.CLIENT_SRC, domain: mainDomain, name: Self.CLIENT_SRC, value: clientSrc)
        setCookieValue(cookieStore: cookieStore, cookieType: Self.SID_CLIENT, domain: mainDomain, name: Self.SID_CLIENT, value: sidClient)
        setCookieValue(cookieStore: cookieStore, cookieType: Self.ORG_ID, domain: mainDomain, name: Self.ORG_ID, value: orgId)
        setCookieValue(cookieStore: cookieStore, cookieType: Self.csrfTokenCookieName, domain: mainDomain, name: Self.csrfTokenCookieName, value: csrfToken)
        
        // Lightning domain cookies
        setCookieValue(cookieStore: cookieStore, cookieType: "sid for lightning", domain: lightningDomain, name: sidCookieName, value: lightningSid)
        setCookieValue(cookieStore: cookieStore, cookieType: Self.csrfTokenCookieName, domain: lightningDomain, name: Self.csrfTokenCookieName, value: csrfToken)
        
        // Content domain cookies
        setCookieValue(cookieStore: cookieStore, cookieType: "sid for content", domain: contentDomain, name: sidCookieName, value: contentSid)
        
        // Vf domain cookies
        setCookieValue(cookieStore: cookieStore, cookieType: "sid for vf", domain: vfDomain, name: sidCookieName, value: vfSid)
        setCookieValue(cookieStore: cookieStore, cookieType: Self.CLIENT_SRC, domain: vfDomain, name: Self.CLIENT_SRC, value: clientSrc)
        setCookieValue(cookieStore: cookieStore, cookieType: Self.SID_CLIENT, domain: vfDomain, name: Self.SID_CLIENT, value: sidClient)
        setCookieValue(cookieStore: cookieStore, cookieType: Self.ORG_ID, domain: vfDomain, name: Self.ORG_ID, value: orgId)
        
        SFSDKHybridLogger.i(Self.self, message: "[\(Self.self) \(#function)]: done setting cookies for \(String(describing: creds.userId)).")
        completion()
    }

    @MainActor private func setCookieValue(cookieStore: WKHTTPCookieStore, cookieType: String, domain: String?, name: String?, value: String?) {
        guard let domain = domain, let name = name, let value = value else {
            SFSDKHybridLogger.w(Self.self, message: "[\(Self.self) \(#function)]: unable to set \(cookieType) in domain:\(domain ?? "nil")")
            return
        }

        let properties: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .domain: domain,
            .path: "/",
            .secure: true,
            .discard: true
        ]

        if let cookie = HTTPCookie(properties: properties) {
            cookieStore.setCookie(cookie)
            SFSDKHybridLogger.d(Self.self, message: "[\(Self.self) \(#function)]: setting \(cookieType) in domain:\(domain) with value:\(value)")
        }
    }
    
    private func getDomainFromUrl(_ url: URL?) -> String {
        return url?.host ?? ""
    }

    static let CLIENT_SRC = "clientSrc"
    static let SID_CLIENT = "sid_Client"
    static let ORG_ID = "oid"
    static let csrfTokenCookieName = "eikoocnekotMob"
}
