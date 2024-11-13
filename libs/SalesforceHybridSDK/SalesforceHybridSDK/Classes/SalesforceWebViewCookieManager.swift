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
        self.setCookies(userAccount: userAccount)
        completion()
    }
    
    @MainActor func setCookies(userAccount: UserAccount) {
        SFSDKHybridLogger.i(Self.self, message: "[\(Self.self) \(#function)]: setting cookies for \(String(describing: userAccount.credentials.userId)).")
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        let instanceUrl = userAccount.credentials.instanceUrl
        let lightningDomain = userAccount.credentials.lightningDomain
        let lightningSid = userAccount.credentials.lightningSid
        let contentDomain = userAccount.credentials.contentDomain
        let contentSid = userAccount.credentials.contentSid
        let mainSid = userAccount.credentials.accessToken
        let vfDomain = userAccount.credentials.vfDomain
        let vfSid = userAccount.credentials.vfSid
        let clientSrc = userAccount.credentials.cookieClientSrc
        let sidClient = userAccount.credentials.cookieSidClient
        let sidCookieName = userAccount.credentials.sidCookieName
        let csrfToken = userAccount.credentials.csrfToken
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
        
        SFSDKHybridLogger.i(Self.self, message: "[\(Self.self) \(#function)]: done setting cookies for \(String(describing: userAccount.credentials.userId)).")
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
    
    private func getHttpsUrlFromDomain(domain: String) -> URL {
        if domain.contains("://") {
            return URL(string: domain) ?? URL(string: "https://\(domain)")!
        } else {
            return URL(string: "https://\(domain)")!
        }
    }

    private func getDomainFromUrl(_ url: URL?) -> String {
        return url?.host ?? ""
    }

    static let CLIENT_SRC = "clientSrc"
    static let SID_CLIENT = "sid_Client"
    static let ORG_ID = "oid"
    static let csrfTokenCookieName = "eikoocnekotMob"
    private static let TAG = "SalesforceWebViewCookieManager"
}

/*
import WebKit

public class CookieManager: NSObject {
    let user: UserInfo
    private(set) var isMonitoringCookieStore = false
    let localCookieStore: LocalCookieStore
    let sidCookieName: String
    let sidClientCookieName = "sid_Client"
    let clientSrcCookieName = "clientSrc"
    let oidCookieName = "oid"
    let csrfCookieName = "eikoocnekotMob"
    
    public init(user: UserInfo, localCookieStore: LocalCookieStore) {
        self.user = user
        self.localCookieStore = localCookieStore
        if let sidName = user.authenticationData.sidCookieName {
            sidCookieName = sidName
        } else {
            sidCookieName = "sid"
        }
    }
    
    private enum FdReplacementError: Error, CustomStringConvertible {
        // Error messages should be used for debugging purposes only.
        case MissingMainSidCookie
        case MissingLightningSidCookie
        case MissingContentSidCookie
        case MissingVFSidCookie
        case InvalidApiDomain
        case InvalidSidClient
        case FailedToMakeSidClientCookie
        case InvalidClientSrc
        case FailedToMakeClientSrcCookie
        case FailedToMakeOIDCookie
        
        var description: String {
            switch self {
            case .MissingMainSidCookie:
                return "FdReplacementError: Missing main sid cookie."
            case .MissingLightningSidCookie:
                return "FdReplacementError: Missing lightning sid cookie."
            case .MissingContentSidCookie:
                return "FdReplacementError: Missing content sid cookie."
            case .MissingVFSidCookie:
                return "FdReplacementError: Missing vf sid cookie."
            case .InvalidApiDomain:
                return "FdReplacementError: Fail to get api domain from user auth data."
            case .InvalidSidClient:
                return "FdReplacementError: Fail to get sid client from user auth data"
            case .FailedToMakeSidClientCookie:
                return "FdReplacementError: Fail to populate sid client cookie"
            case .InvalidClientSrc:
                return "FdReplacementError: Fail to get client src from user auth data"
            case  .FailedToMakeClientSrcCookie:
                return "FdReplacementError: Fail to populate client src cookie"
            case .FailedToMakeOIDCookie:
                return "FdReplacementError: Fail to populate oid cookie"
            }
        }
    }
    
    deinit {
        if !GlobalConfiguration.skipDeinitCookieManager() {
            DispatchQueue.syncOnMain {
                self.httpCookieStore.remove(self)
            }
        }
    }
    
    var httpCookieStore: WKHTTPCookieStore {
        return WKWebView.bifrostDataStore.httpCookieStore
    }
    
    func applyFrontDoorCookies(completionHandler: @escaping ((Error?) -> Void)) {
        do {
            // first populate session cookies (should include sids cookies e.g. main, lightnig, content, visualforce domains)
            var cookies = try populateUpdatedSessionCookies()
            
            guard cookies.contains(where: { $0.isMainSidCookie(forUser: user) }) else {
                throw FdReplacementError.MissingMainSidCookie
            }
            guard let domain = user.authenticationData.apiUrl?.host else {
                throw FdReplacementError.InvalidApiDomain
            }
            guard let clientSrc = user.authenticationData.clientSrc else {
                throw FdReplacementError.InvalidClientSrc
            }
            guard let sidClient = user.authenticationData.sidClient else {
                throw FdReplacementError.InvalidSidClient
            }
            
            try updateOrPopulateAdditionalCookies(&cookies, sidClient: sidClient, clientSrc: clientSrc, domain: domain, toThrow: true)
            
            if let vfDomain = user.authenticationData.visualforceDomain {
                try updateOrPopulateAdditionalCookies(&cookies, sidClient: sidClient, clientSrc: clientSrc, domain: vfDomain, toThrow: false)
            } else {
                LogTool.log("VF Cookies not applied because a VF domain is not available from authentication data.")
            }
            
            DispatchQueue.syncOnMain {
                LogTool.log("Setting front door cookies to WKWebView's HTTP cookie store")
                self.httpCookieStore.setCookies(cookies) {
                    completionHandler(nil)
                }
            }
        } catch {
            if let err = error as? FdReplacementError {
                LogTool.logWarning(err.description)
            }
            completionHandler(error)
        }
    }
    
    func startMonitoringCookieStore() {
        guard !isMonitoringCookieStore else { return }
        LogTool.log("Started monitoring cookie store.")
        isMonitoringCookieStore = true
        DispatchQueue.syncOnMain {
            self.httpCookieStore.add(self)
        }
    }
    
    func stopMonitoringCookieStore() {
        guard isMonitoringCookieStore else { return }
        LogTool.log("Stopped monitoring cookie store.")
        DispatchQueue.syncOnMain {
            self.httpCookieStore.remove(self)
        }
        isMonitoringCookieStore = false
    }
    
    func hasSavedUserSessionCookies() -> Bool {
        let mainSessionCookies = localCookieStore.cookiesForUser(user).filter {
            $0.isMainSidCookie(forUser: user)
        }
        return !mainSessionCookies.isEmpty
    }
    
    func saveSessionCookies() {
        DispatchQueue.syncOnMain {
            self.httpCookieStore.getAllCookies { cookies in
                let sessionCookies = self.sessionCookies(from: cookies)
                if !sessionCookies.isEmpty {
                    LogTool.log("Saving cookie updates for user id: \(String(describing: self.user.userId))")
                    self.localCookieStore.saveCookies(sessionCookies, user: self.user)
                }
            }
        }
    }
    
    private func sessionCookies(from cookies: [HTTPCookie]) -> [HTTPCookie] {
        return cookies.filter { $0.isSessionCookie }
    }
    
    public func loadSessionCookies(completionHandler: @escaping (() -> Void)) {
        LogTool.log("Loading session cookies for user id: \(String(describing: user.userId))")
        do {
            let cookies = try populateUpdatedSessionCookies()
            DispatchQueue.syncOnMain {
                LogTool.log("Setting cookies to WKWebView's HTTP cookie store")
                self.httpCookieStore.setCookies(cookies) {
                    completionHandler()
                }
            }
        } catch {
            if let err = error as? FdReplacementError {
                LogTool.logError(err.description)
                completionHandler()
            }
        }
    }
    
    func deleteSessionCookies() {
        LogTool.log("Deleting session cookies for user id: \(user.userId)")
        localCookieStore.deleteCookiesForUser(user)
    }
    
    public func hasSIDCookies(for domain: String) -> Bool {
        return allSIDCookies().contains {
            var cookieDomain = $0.domain
            if cookieDomain.hasPrefix(".") {
                cookieDomain = String(cookieDomain.suffix(cookieDomain.count - 1))
            }
            return cookieDomain == domain
        }
    }
    
    public func allSIDCookies() -> [HTTPCookie] {
        var cookies = localCookieStore.cookiesForUser(user).filter { $0.name == sidCookieName }
        guard let lightningCookie = user.authenticationData.lightningSIDCookie else { return cookies }
        
        let didFindLightningCookie = cookies.contains {
            $0.name == lightningCookie.name && $0.value == lightningCookie.value && $0.domain == lightningCookie.domain
        }
        if !didFindLightningCookie {
            LogTool.log("Adding user lightning SID cookie into SID cookies from local store.")
            cookies.append(lightningCookie)
        }
        return cookies
    }
    
    // MARK: - Private methods
    private func makeSIDCookie(_ sid: String, domain: String) -> HTTPCookie? {
        return makeCookie(name: sidCookieName, value: sid, domain: domain)
    }
    
    private func makeCookie(name: String, value: String, domain: String) -> HTTPCookie? {
        return HTTPCookie(properties: [.name: name,
                                       .value: value,
                                       .domain: domain,
                                       .path: "/",
                                       .secure: true,
                                       .discard: true])
    }
    
    private func populateUpdatedSessionCookies() throws -> [HTTPCookie] {
        var cookies = localCookieStore.cookiesForUser(user)
        
        try updateMainSidIfProvided(&cookies)
        try updateLightningSidIfProvided(&cookies)
        try updateContentSidIfProvided(&cookies)
        if GlobalConfiguration.enableFrontDoorReplacement() {
            try updateVFSidIfProvided(&cookies)
        }
        return cookies
    }
    
    private func updateOrPopulateAdditionalCookies(_ cookies: inout [HTTPCookie], sidClient: String, clientSrc: String, domain: String, toThrow: Bool) throws {
        // update or add clientSrc cookie
        try updateOrAddCookie(&cookies, cookieName: clientSrcCookieName, value: clientSrc, domain: domain, throwsError: FdReplacementError.FailedToMakeClientSrcCookie)
        // update or add sidClient cookie
        try updateOrAddCookie(&cookies, cookieName: sidClientCookieName, value: sidClient, domain: domain, throwsError: FdReplacementError.FailedToMakeSidClientCookie)
        // update or add oid cookie
        try updateOrAddCookie(&cookies, cookieName: oidCookieName, value: user.organizationId, domain: domain, throwsError: FdReplacementError.FailedToMakeOIDCookie)
    }
    
    private func updateOrAddCookie(_ cookies: inout [HTTPCookie], cookieName: String, value: String, domain: String, throwsError: FdReplacementError?) throws {
        if !containsCookie(cookies, cookieName: cookieName, value: value, domain: domain) {
            if let cookie = makeCookie(name: cookieName, value: value, domain: domain) {
                cookies.append(cookie)
            } else {
                if let err = throwsError {
                    throw err
                } else {
                    LogTool.logWarning("IMPORTANT: Fail to apply " + cookieName + " on domain:" + domain)
                }
            }
        }
    }
    
    private func containsCookie(_ cookies: [HTTPCookie], cookieName: String, value: String, domain: String) -> Bool {
        let contains = cookies.contains { cookie in
            if cookie.name == cookieName, cookie.domain == domain, cookie.value == value {
                return true
            }
            return false
        }
        return contains
    }
    
    private func updateMainSidIfProvided(_ cookies: inout [HTTPCookie]) throws {
        if let sid = user.authenticationData.accessToken, let domain = user.authenticationData.apiUrl?.host {
            cookies = HTTPCookie.applySID(sid, toMainSessionCookiesIn: cookies, forUser: user)
            let containsMainCookie = cookies.contains { $0.isMainSidCookie(forUser: user) }
            if !containsMainCookie {
                if let mainCookie = makeSIDCookie(sid, domain: domain) {
                    LogTool.log("Main cookie artificially created since one was not found in local BHC store.")
                    cookies.append(mainCookie)
                } else {
                    throw FdReplacementError.MissingMainSidCookie
                }
            }
        } else {
            throw FdReplacementError.MissingMainSidCookie
        }
    }
    
    private func updateLightningSidIfProvided(_ cookies: inout [HTTPCookie]) throws {
        if let lightningSID = user.authenticationData.lightningSID, let lightningDomain = user.authenticationData.lightningDomain {
            cookies = HTTPCookie.applySID(lightningSID, toLightningSessionCookiesIn: cookies, forUser: user)
            let containsLightningCookie = cookies.contains { $0.isLightningSidCookie(forUser: user) }
            if !containsLightningCookie {
                if let lightningCookie = makeSIDCookie(lightningSID, domain: lightningDomain) {
                    LogTool.log("Lightning cookie artificially created since one was not found in local BHC store.")
                    cookies.append(lightningCookie)
                } else {
                    throw FdReplacementError.MissingLightningSidCookie
                }
            }
            // apply csrfToken on lightning domain
            if let csrfToken = user.authenticationData.csrfToken, let eikoocnekot = makeCsrfTokenCookie(csrfToken: csrfToken, domain: lightningDomain) {
                cookies.append(eikoocnekot)
            }
        } else {
            LogTool.logWarning("IMPORTANT: Lightning domain auth info was NOT provided.")
            // apply csrfToken on main domain
            if let csrfToken = user.authenticationData.csrfToken, let mainDomain = user.authenticationData.domain, let eikoocnekot = makeCsrfTokenCookie(csrfToken: csrfToken, domain: mainDomain) {
                cookies.append(eikoocnekot)
            }
        }
    }
    
    private func makeCsrfTokenCookie(csrfToken: String, domain: String) -> HTTPCookie? {
        if let eikoocnekot = makeCookie(name: self.csrfCookieName, value: csrfToken, domain: domain) {
            return eikoocnekot
        }
        return nil
    }
    
    private func updateContentSidIfProvided(_ cookies: inout [HTTPCookie]) throws {
        if let contentSID = user.authenticationData.contentSID, let contentDomain = user.authenticationData.contentDomain {
            cookies = HTTPCookie.applySID(contentSID, toContentSessionCookiesIn: cookies, forUser: user)
            let containsContentCookie = cookies.contains { $0.isContentSidCookie(forUser: user) }
            if !containsContentCookie {
                if let contentCookie = makeSIDCookie(contentSID, domain: contentDomain) {
                    LogTool.log("Content cookie artificially created since one was not found in local BHC store.")
                    cookies.append(contentCookie)
                } else {
                    throw FdReplacementError.MissingContentSidCookie
                }
            }
        } else {
            LogTool.logWarning("IMPORTANT: Content domain auth info was NOT provided.")
        }
    }
    
    private func updateVFSidIfProvided(_ cookies: inout [HTTPCookie]) throws {
        if let vfSid = user.authenticationData.visualforceSID, let vfDomain = user.authenticationData.visualforceDomain {
            cookies = HTTPCookie.applySID(vfSid, toVFSessionCookiesIn: cookies, forUser: user)
            let containsVFCookie = cookies.contains { $0.isVFMainSidCookie(forUser: user) }
            if !containsVFCookie {
                if let vfCookie = makeSIDCookie(vfSid, domain: vfDomain) {
                    LogTool.log("VF main cookie artificially created since one was not found in local BHC store.")
                    cookies.append(vfCookie)
                } else {
                    throw FdReplacementError.MissingVFSidCookie
                }
            }
        } else {
            LogTool.logWarning("IMPORTANT: VF main domain auth info was NOT provided.")
        }
    }
}

// MARK: - WKHTTPCookieStoreObserver

extension CookieManager: WKHTTPCookieStoreObserver {
    public func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self, strongSelf.httpCookieStore === cookieStore, strongSelf.isMonitoringCookieStore else { return }
            strongSelf.saveSessionCookies()
        }
    }
}
*/
