/*
 Copyright (c) 2012-present, salesforce.com, inc. All rights reserved.
 Author: Kevin Hawkins
 
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

#import "SFHybridViewController.h"
#import "SFHybridConnectionMonitor.h"
#import "SalesforceHybridSDKManager.h"
#import "SFSDKHybridLogger.h"
#import <SalesforceSDKCore/SFSDKAppFeatureMarkers.h>
#import <SalesforceSDKCore/SalesforceSDKManager.h>
#import <SalesforceSDKCore/NSURL+SFStringUtils.h>
#import <SalesforceSDKCore/NSURL+SFAdditions.h>
#import <SalesforceSDKCore/SFAuthErrorHandlerList.h>
#import <SAlesforceSDKCore/SFSDKAuthConfigUtil.h>
#import <SalesforceSDKCore/SFSDKWebUtils.h>
#import <SalesforceSDKCore/SFSDKResourceUtils.h>
#import <SalesforceSDKCore/SFSDKEventBuilderHelper.h>
#import <SalesforceSDKCore/NSString+SFAdditions.h>
#import <SalesforceSDKCore/SFSDKWebViewStateManager.h>
#import <SalesforceSDKCore/SFRestAPI+Blocks.h>
#import <Cordova/NSDictionary+CordovaPreferences.h>
#import <objc/message.h>
#import <SalesforceHybridSDK/SalesforceHybridSDK-Swift.h>

// Public constants.
NSString * const kAppHomeUrlPropKey = @"AppHomeUrl";
NSString * const kAccessTokenCredentialsDictKey = @"accessToken";
NSString * const kRefreshTokenCredentialsDictKey = @"refreshToken";
NSString * const kClientIdCredentialsDictKey = @"clientId";
NSString * const kUserIdCredentialsDictKey = @"userId";
NSString * const kOrgIdCredentialsDictKey = @"orgId";
NSString * const kLoginUrlCredentialsDictKey = @"loginUrl";
NSString * const kInstanceUrlCredentialsDictKey = @"instanceUrl";
NSString * const kUserAgentCredentialsDictKey = @"userAgent";
NSString * const kCommunityIdCredentialsDictKey= @"communityId";
NSString * const kCommunityUrlCredentialsDictKey= @"communityUrl";

// Error page constants.
static NSString * const kErrorCodeParameterName = @"errorCode";
static NSString * const kErrorDescriptionParameterName = @"errorDescription";
static NSString * const kErrorContextParameterName = @"errorContext";
static NSInteger  const kErrorCodeNetworkOffline = 1;
static NSInteger  const kErrorCodeNoCredentials = 2;
static NSString * const kErrorContextAppLoading = @"AppLoading";
static NSString * const kErrorContextAuthExpiredSessionRefresh = @"AuthRefreshExpiredSession";
static NSString * const kVFPingPageUrl = @"/apexpages/utils/ping.apexp";

// Session redirect constants.
static NSString * const kHybridSessionRedirect = @"/services/identity/mobileauthredirect";
static NSString * const kFrontdoor = @"frontdoor.jsp";
static NSString * const kStartURLParam = @"startURL";
static NSString * const kRetURLParam = @"retURL";
static NSString * const kECParam = @"ec";
static NSString * const kEC301 = @"301";
static NSString * const kEC302 = @"302";
static NSString * const kQuestionMark = @"?";
static NSString * const kHTTP = @"http";

@interface SFHybridViewController()
{
    BOOL _foundHomeUrl;
    SFHybridViewConfig *_hybridViewConfig;
}

/**
 * WKWebView for processing the error page, in the event of a fatal error during bootstrap.
 */
@property (nonatomic, strong) WKWebView *errorPageWKWebView;

@property (nonatomic, strong) SFOAuthOrgAuthConfiguration *authConfig;

/**
 * Cookie manager responsible for hydrating session of web view in hybrid remote apps
 */
@property (nonatomic, strong) SFSDKSalesforceWebViewCookieManager *cookieManager;

/**
 * Whether or not the input URL is one of the reserved URLs in the login flow, for consideration
 * in determining the app's ultimate home page.
 *
 * @param url The URL to test.
 * @return YES - if the value is one of the reserved URLs, NO - otherwise.
 */
- (BOOL)isReservedUrlValue:(NSURL *)url;

/**
 * Reports whether the device is offline.
 *
 * @return YES - if the device is offline, NO - otherwise.
 */
- (BOOL)isOffline;

/**
 * Determines whether the error is due to invalid credentials, and if so, whether the
 * app should be logged out as a result.
 *
 * @param error The error to check against an invalid credentials error.
 * @return YES - if the error is due to invalid credentials and logout should occur, NO - otherwise.
 */
- (BOOL)logoutOnInvalidCredentials:(NSError *)error;

/**
 * Gets the file URL for the full path to the given page.
 *
 * @param page The relative page to create the path from.
 * @return NSURL representing the file URL for the page path.
 */
- (NSURL *)fullFileUrlForPage:(NSString *)page;

/**
 * Appends the error contents as querystring parameters to the input URL.
 *
 * @param rootUrl The base URL to use.
 * @param errorCode The numeric error code associated with the error.
 * @param errorDescription The error description associated with the error.
 * @param errorContext The error context associated with the error.
 * @return NSURL containing the base URL and the error parameter.
 */
- (NSURL *)createErrorPageUrl:(NSURL *)rootUrl code:(NSInteger)errorCode description:(NSString *)errorDescription context:(NSString *)errorContext;

/**
 * Creates a default in-memory error page, in the event that a user-defined error page does not exist.
 *
 * @param errorCode The numeric error code associated with the error.
 * @param errorDescription The error description associated with the error.
 * @param errorContext The context associated with the error.
 * @return An NSString containing the HTML content for the error page.
 */
- (NSString *)createDefaultErrorPageContentWithCode:(NSInteger)errorCode description:(NSString *)errorDescription context:(NSString *)errorContext;

@end

@implementation SFHybridViewController

- (id) init
{
    return [self initWithConfig:nil];
}

- (id) initWithConfig:(SFHybridViewConfig *) viewConfig
{
    self = [super init];
    if (self) {
        _cookieManager = [[SFSDKSalesforceWebViewCookieManager alloc] init];
        _hybridViewConfig = (viewConfig == nil ? [SFHybridViewConfig fromDefaultConfigFile] : viewConfig);
        NSAssert(_hybridViewConfig != nil, @"_hybridViewConfig was not properly initialized. See output log for errors.");
        self.startPage = _hybridViewConfig.startPage;

        // Setup global stores and syncs defined in static configs
        [[SalesforceHybridSDKManager sharedManager] setupGlobalStoreFromDefaultConfig];
        [[SalesforceHybridSDKManager sharedManager] setupGlobalSyncsFromDefaultConfig];
        __weak typeof(self) weakSelf = self;
        [SFSDKAuthConfigUtil getMyDomainAuthConfig:^(SFOAuthOrgAuthConfiguration *authConfig, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
                    strongSelf.authConfig = authConfig;
                }
            });
        } loginDomain:[SFUserAccountManager sharedInstance].loginHost];

        // Auth failure callback block.
        _authFailureCallbackBlock = ^(SFOAuthInfo *authInfo, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if ([strongSelf logoutOnInvalidCredentials:error]) {
                [SFSDKHybridLogger e:[strongSelf class] message:@"Could not refresh expired session. Logging out."];
                NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
                attributes[@"errorCode"] = [NSNumber numberWithInteger:error.code];
                attributes[@"errorDescription"] = error.localizedDescription;
                [SFSDKEventBuilderHelper createAndStoreEvent:@"userLogout" userAccount:nil className:NSStringFromClass([strongSelf class]) attributes:attributes];
                [[SFUserAccountManager sharedInstance] logout];
            } else {

                // Error is not invalid credentials, or developer otherwise wants to handle it.
                [strongSelf loadErrorPageWithCode:error.code description:error.localizedDescription context:kErrorContextAuthExpiredSessionRefresh];
            }
        };
    }
    return self;
}

- (void)dealloc
{
    self.errorPageWKWebView.navigationDelegate = nil;
    SFRelease(_errorPageWKWebView);
}

- (void)viewDidLoad
{
    NSString *hybridViewUserAgentString = [self sfHybridViewUserAgentString];
    [SFSDKWebUtils configureUserAgent:hybridViewUserAgentString];
    [self.settings setCordovaSetting:hybridViewUserAgentString forKey:@"OverrideUserAgent"];

    // If this app requires authentication at startup, and authentication hasn't happened, that's an error.
    NSString *accessToken = [SFUserAccountManager sharedInstance].currentUser.credentials.accessToken;
    if (_hybridViewConfig.shouldAuthenticate && [accessToken length] == 0) {
        NSString *noCredentials = [SFSDKResourceUtils localizedString:@"hybridBootstrapNoCredentialsAtStartup"];
        [self loadErrorPageWithCode:kErrorCodeNoCredentials description:noCredentials context:kErrorContextAppLoading];
        return;
    }
    
    // Setup user stores and syncs defined in static configs
    if ([SFUserAccountManager sharedInstance].currentUser) {
        [[SalesforceHybridSDKManager sharedManager] setupUserStoreFromDefaultConfig];
        [[SalesforceHybridSDKManager sharedManager] setupUserSyncsFromDefaultConfig];
    }

    // If the app is local, we should just be able to load it.
    if (_hybridViewConfig.isLocal) {
        [super viewDidLoad];
        return;
    }

    // Remote app. If the device is offline, we should attempt to load cached content.
    if ([self isOffline]) {

        // Device is offline, and we have to try to load cached content.
        NSString *urlString = [self.appHomeUrl absoluteString];
        if (_hybridViewConfig.attemptOfflineLoad && [urlString length] > 0) {

            // Try to load offline page.
            self.startPage = urlString;
            [super viewDidLoad];
        } else {
            NSString *offlineErrorDescription = [SFSDKResourceUtils localizedString:@"hybridBootstrapDeviceOffline"];
            [self loadErrorPageWithCode:kErrorCodeNetworkOffline description:offlineErrorDescription context:kErrorContextAppLoading];
        }
        return;
    }

    // Remote app. Device is online.
    if ([self userIsAuthenticated]) {
        [SFSDKHybridLogger i:[self class] format:@"[%@ %@]: Preparing web state before loading start page.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
        [self prepareWebState:^{
            [self configureRemoteStartPage];
            [super viewDidLoad];
        }];
    } else {
        [self configureRemoteStartPage];
        [super viewDidLoad];
    }
}

- (NSString *)remoteAccessConsumerKey
{
    return _hybridViewConfig.remoteAccessConsumerKey;
}

- (NSString *)oauthRedirectURI
{
    return _hybridViewConfig.oauthRedirectURI;
}

- (NSSet *)oauthScopes
{
    return _hybridViewConfig.oauthScopes;
}

- (NSURL *)appHomeUrl
{
    return [[NSUserDefaults standardUserDefaults] URLForKey:kAppHomeUrlPropKey];
}

- (void)setAppHomeUrl:(NSURL *)appHomeUrl
{
    [[NSUserDefaults standardUserDefaults] setURL:appHomeUrl forKey:kAppHomeUrlPropKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (SFHybridViewConfig *)hybridViewConfig
{
    return _hybridViewConfig;
}

- (void)authenticateWithCompletionBlock:(SFOAuthPluginAuthSuccessBlock)completionBlock failureBlock:(SFOAuthPluginFailureBlock)failureBlock
{
    /*
     * Reconfigure user agent. Basically this ensures that Cordova whitelisting won't apply to the
     * WKWebView that hosts the login screen (important for SSO outside of Salesforce domains).
     */
    [SFSDKWebUtils configureUserAgent:[self sfHybridViewUserAgentString]];
    __weak __typeof(self) weakSelf = self;
    SFUserAccountManagerSuccessCallbackBlock authCompletionBlock = ^(SFOAuthInfo *authInfo, SFUserAccount *userAccount) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf authenticationCompletion:nil authInfo:authInfo];
        if (completionBlock != NULL) {
            NSDictionary *authDict = [self credentialsAsDictionary];
            completionBlock(authInfo, authDict);
        }
    };
    SFOAuthPluginFailureBlock authFailureBlock = ^(SFOAuthInfo *authInfo, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf logoutOnInvalidCredentials:error]) {
            [SFSDKHybridLogger d:[strongSelf class] message:@"OAuth plugin authentication request failed. Logging out."];
            NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
            attributes[@"errorCode"] = [NSNumber numberWithInteger:error.code];
            attributes[@"errorDescription"] = error.localizedDescription;
            [SFSDKEventBuilderHelper createAndStoreEvent:@"userLogout" userAccount:nil className:NSStringFromClass([self class]) attributes:attributes];
            [[SFUserAccountManager sharedInstance] logout];
        } else if (failureBlock != NULL) {
            failureBlock(authInfo, error);
        }
    };
    if (![SFUserAccountManager sharedInstance].currentUser) {
        [[SFUserAccountManager sharedInstance] loginWithCompletion:authCompletionBlock failure:authFailureBlock];
    } else {
        [[SFUserAccountManager sharedInstance] refreshCredentials:[SFUserAccountManager sharedInstance].currentUser.credentials completion:authCompletionBlock
            failure:authFailureBlock];
    }
}

- (void)loadErrorPageWithCode:(NSInteger)errorCode description:(NSString *)errorDescription context:(NSString *)errorContext
{
    NSString *errorPage = _hybridViewConfig.errorPage;
    NSURL *errorPageUrl = [self fullFileUrlForPage:errorPage];

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.processPool = SFSDKWebViewStateManager.sharedProcessPool;
    self.errorPageWKWebView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:config];
    self.errorPageWKWebView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.errorPageWKWebView.navigationDelegate = self;
    [self.view addSubview:self.errorPageWKWebView];

    if (errorPageUrl != nil) {
        NSURL *errorPageUrlWithError = [self createErrorPageUrl:errorPageUrl code:errorCode description:errorDescription context:errorContext];
        NSURLRequest *errorRequest = [NSURLRequest requestWithURL:errorPageUrlWithError];
        [self.errorPageWKWebView loadRequest:errorRequest];
    } else {
        // Error page does not exist. Generate a generic page with the error.
        NSString *errorContent = [self createDefaultErrorPageContentWithCode:errorCode description:errorDescription context:errorContext];
        [self.errorPageWKWebView loadHTMLString:errorContent baseURL:nil];
    }
}

- (NSDictionary *)credentialsAsDictionary
{
    NSDictionary *credentialsDict = nil;
    SFOAuthCredentials *creds = [SFUserAccountManager sharedInstance].currentUser.credentials;
    if (nil != creds) {
        NSString *instanceUrl = creds.instanceUrl.absoluteString;
        NSString *loginUrl = [NSString stringWithFormat:@"%@://%@", creds.protocol, creds.domain];
        NSString *communityUrl = creds.communityUrl ? creds.communityUrl.absoluteString : nil;
        NSString *uaString = [self sfHybridViewUserAgentString];
        credentialsDict = @{kAccessTokenCredentialsDictKey: creds.accessToken,
                           kRefreshTokenCredentialsDictKey: creds.refreshToken,
                           kClientIdCredentialsDictKey: creds.clientId,
                           kUserIdCredentialsDictKey: creds.userId,
                           kOrgIdCredentialsDictKey: creds.organizationId,
                           kCommunityIdCredentialsDictKey: creds.communityId ?: [NSNull null],
                           kCommunityUrlCredentialsDictKey: communityUrl ?: [NSNull null],
                           kLoginUrlCredentialsDictKey: loginUrl,
                           kInstanceUrlCredentialsDictKey: instanceUrl,
                           kUserAgentCredentialsDictKey: uaString};
    }
    return credentialsDict;
}

- (NSString *)sfHybridViewUserAgentString
{
    NSString *userAgentString = @"";
    if ([SalesforceSDKManager sharedManager].userAgentString != NULL) {
        if (_hybridViewConfig.isLocal) {
            userAgentString = [SalesforceSDKManager sharedManager].userAgentString(@"Local");
        } else {
            userAgentString = [SalesforceSDKManager sharedManager].userAgentString(@"Remote");
        }
    }
    return userAgentString;
}

- (NSURL *)absoluteUrlWithUrl:(NSString *)url
{
    SFOAuthCredentials *creds = [SFUserAccountManager sharedInstance].currentUser.credentials;
    NSURL *instUrl = creds.apiUrl;
    NSString *fullUrl = url;

    if (![url hasPrefix:kHTTP]) {
        NSURLComponents *retUrlComponents = [NSURLComponents componentsWithURL:instUrl resolvingAgainstBaseURL:NO];
        NSString* pathToAppend = [url hasPrefix:@"/"] ? url : [NSString stringWithFormat:@"/%@", url];
        retUrlComponents.path = [retUrlComponents.path stringByAppendingString:pathToAppend];
        fullUrl = retUrlComponents.string;
    }

    return [NSURL URLWithString:fullUrl];
}

- (NSString *)isLoginRedirectUrl:(NSURL *)url
{
    if (url == nil || url.absoluteString == nil || url.absoluteString.length == 0) {
        return nil;
    }
    if ([url.scheme.lowercaseString hasPrefix:kHTTP]) {
        NSString *retUrlValue = nil;
        if (url.query != nil) {
            retUrlValue = [url sfsdk_valueForParameterName:kRetURLParam];
            retUrlValue = (retUrlValue == nil) ? [url sfsdk_valueForParameterName:kStartURLParam] : retUrlValue;
            retUrlValue = [retUrlValue stringByRemovingPercentEncoding];
        }
        if (retUrlValue == nil || [retUrlValue containsString:kFrontdoor]) {
            retUrlValue = self.startPage;
        }
        if ([self isSessionExpirationRedirect:url.absoluteString] || [self isSamlLoginRedirect:url.absoluteString] || [self isVFPageRedirect:url]) {
            return retUrlValue;
        }
    }
    return nil;
}

- (BOOL)isSessionExpirationRedirect:(NSString *)url {
    return (url && [url containsString:kHybridSessionRedirect]);
}

- (BOOL)isSamlLoginRedirect:(NSString *)url {
    if (self.authConfig) {
        NSString *loginPageUrl = self.authConfig.loginPageUrl;
        if (loginPageUrl && [url containsString:loginPageUrl]) {
            return YES;
        }
        NSArray<NSString *> *ssoUrls = self.authConfig.ssoUrls;
        if (ssoUrls && ssoUrls.count > 0) {
            for (NSString *ssoUrl in ssoUrls) {
                NSString *baseUrl = [ssoUrl copy];
                NSRange index = [ssoUrl rangeOfString:kQuestionMark];
                if (index.location != NSNotFound) {
                    baseUrl = [ssoUrl substringToIndex:index.location];
                }
                if ([url containsString:baseUrl]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (BOOL)isVFPageRedirect:(NSURL *)url {
    NSString *ecValue = [url sfsdk_valueForParameterName:kECParam];
    return ([ecValue isEqualToString:kEC301] || [ecValue isEqualToString:kEC302]);
}

- (BOOL)isOffline
{
    SFHybridConnectionMonitor *connection = [SFHybridConnectionMonitor sharedInstance];
    NSString *connectionType = [[connection.connectionType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    return (connectionType == nil || [connectionType length] == 0 || [connectionType isEqualToString:@"unknown"] || [connectionType isEqualToString:@"none"]);
}

- (BOOL)logoutOnInvalidCredentials:(NSError *)error
{
    if ([error.domain isEqualToString:kSFOAuthErrorDomain] && error.code == kSFOAuthErrorInvalidGrant) {
        return YES;
    }
    return NO;
}

- (NSURL *)fullFileUrlForPage:(NSString *)page
{
    NSString *fullPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.wwwFolderName] stringByAppendingPathComponent:page];
    NSFileManager *manager = [[NSFileManager alloc] init];
    if (![manager fileExistsAtPath:fullPath]) {
        return nil;
    }
    NSURL *fileUrl = [NSURL fileURLWithPath:fullPath];
    return fileUrl;
}

- (NSURL *)createErrorPageUrl:(NSURL *)rootUrl code:(NSInteger)errorCode description:(NSString *)errorDescription context:(NSString *)errorContext
{
    NSMutableString *errorPageUrlString = [NSMutableString stringWithString:[rootUrl absoluteString]];
    [rootUrl query] == nil ? [errorPageUrlString appendString:@"?"] : [errorPageUrlString appendString:@"&"];
    [errorPageUrlString appendFormat:@"%@=%ld", kErrorCodeParameterName, (long)errorCode];
    [errorPageUrlString appendFormat:@"&%@=%@", kErrorDescriptionParameterName, [errorDescription sfsdk_stringByURLEncoding]];
    [errorPageUrlString appendFormat:@"&%@=%@", kErrorContextParameterName, [errorContext sfsdk_stringByURLEncoding]];
    return [NSURL URLWithString:errorPageUrlString];
}

- (NSString *)createDefaultErrorPageContentWithCode:(NSInteger)errorCode description:(NSString *)errorDescription context:(NSString *)errorContext
{
    NSString *htmlContent = [NSString stringWithFormat:
                             @"<html>\
                             <head>\
                               <title>Bootstrap Error Page</title>\
                             </head>\
                             <body>\
                               <h1>Bootstrap Error Page</h1>\
                               <p>Error code: %ld</p>\
                               <p>Error description: %@</p>\
                               <p>Error context: %@</p>\
                             </body>\
                             </html>", (long)errorCode, errorDescription, errorContext];
    return htmlContent;
}

- (void)configureRemoteStartPage
{
    
    // Note: You only want this to ever run once in the view controller's lifetime.
    static BOOL startPageConfigured = NO;
    if ([self userIsAuthenticated]) {
        self.startPage = [[self absoluteUrlWithUrl:_hybridViewConfig.startPage] absoluteString];
    } else {
        self.startPage = _hybridViewConfig.unauthenticatedStartPage;
    }
    startPageConfigured = YES;
}

- (void)prepareWebState:(void (^)(void))completion
{
    [SFSDKHybridLogger i:[self class] format:@"[%@ %@]: preparing web state.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
    
    dispatch_async(dispatch_get_main_queue(), ^{

        // Cleaning up old cookies
        [SFSDKHybridLogger i:[self class] format:@"[%@ %@]: resetting session cookies.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
        [SFSDKWebViewStateManager resetSessionCookie];

        // Setting cookies we got from token end point
        // NB: you must be using an hybrid auth flow
        [self.cookieManager setCookiesWithUserAccount:[SFUserAccountManager sharedInstance].currentUser
                                           completion:^{
            if (completion) {
                completion();
            }
        }];
    });
}

- (BOOL)userIsAuthenticated
{
    return ([SFUserAccountManager sharedInstance].currentUser.credentials.accessToken.length > 0);
}

- (void) webView:(WKWebView *) webView didStartProvisionalNavigation:(WKNavigation *) navigation
{
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginResetNotification object:webView]];
}

- (void) webView:(WKWebView *) webView decidePolicyForNavigationAction:(WKNavigationAction *) navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy)) decisionHandler
{
    [SFSDKHybridLogger d:[self class] format:@"webView:decidePolicyForNavigationAction:decisionHandler: Loading URL '%@'",
             [navigationAction.request.URL sfsdk_redactedAbsoluteString:@[@"sid"]]];
    BOOL shouldAllowRequest = YES;
    if ([webView isEqual:self.errorPageWKWebView]) { // Local error page load.
        [SFSDKHybridLogger d:[self class] format:@"Local error page ('%@') is loading.", navigationAction.request.URL.absoluteString];
    } else if ([webView isEqual:self.webView]) { // Cordova web view load.

        /*
         * If the request is attempting to refresh an invalid session, take over
         * the refresh process via the OAuth refresh flow in the container.
         */
        NSString *refreshUrl = [self isLoginRedirectUrl:navigationAction.request.URL];
        if (refreshUrl != nil) {
            [SFSDKHybridLogger w:[self class] message:@"Caught login redirect from session timeout. Reauthenticating."];

            // Auth success callback block.
            __weak typeof(self) weakSelf = self;
            SFUserAccountManagerSuccessCallbackBlock authSuccessCallbackBlock = ^(SFOAuthInfo *authInfo, SFUserAccount *userAccount) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf authenticationCompletion:refreshUrl authInfo:authInfo];
            };

            /*
             * Reconfigure user agent. Basically this ensures that Cordova whitelisting won't apply to the
             * WKWebView that hosts the login screen (important for SSO outside of Salesforce domains).
             */
            [SFSDKWebUtils configureUserAgent:[self sfHybridViewUserAgentString]];
            if (![SFUserAccountManager sharedInstance].currentUser) {
                [[SFUserAccountManager sharedInstance] loginWithCompletion:authSuccessCallbackBlock failure:self.authFailureCallbackBlock];
            } else {
                [self refreshCredentialsWithCompletion:authSuccessCallbackBlock failure:self.authFailureCallbackBlock];
            }
            shouldAllowRequest = NO;
        } else {
            [self defaultWKNavigationHandling:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
            return;
        }
    }
    if (shouldAllowRequest) {
        decisionHandler(WKNavigationActionPolicyAllow);
    } else {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

- (void) defaultWKNavigationHandling:(WKWebView *) webView decidePolicyForNavigationAction:(WKNavigationAction *) navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy)) decisionHandler {
    NSURL *url = [navigationAction.request URL];

    /*
     * Execute any commands queued with cordova.exec() on the JS side.
     * The part of the URL after gap:// is irrelevant.
     */
    if ([[url scheme] isEqualToString:@"gap"]) {
        [self.commandQueue fetchCommandsFromJs];
        
        /*
         * The delegate is called asynchronously in this case, so we don't have to use
         * flushCommandQueueWithDelayedJs (setTimeout(0)) as we do with hash changes.
         */
        [self.commandQueue executePending];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    } else {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLNotification object:url]];
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
}

- (void) webView:(WKWebView *) webView didFinishNavigation:(WKNavigation *) navigation {
    NSURL *requestUrl = webView.URL;
    NSArray *redactParams = @[@"sid"];
    NSString *redactedUrl = [requestUrl sfsdk_redactedAbsoluteString:redactParams];
    [SFSDKHybridLogger d:[self class] format:@"finishLoadActions: Loaded %@", redactedUrl];
    if ([webView isEqual:self.webView]) {

        /*
         * The first URL that's loaded that's not considered a 'reserved' URL (i.e. one that Salesforce or
         * this app's infrastructure is responsible for) will be considered the "app home URL", which can
         * be loaded directly in the event that the app is offline.
         */
        if (_foundHomeUrl == NO) {
            [SFSDKHybridLogger i:[self class] format:@"Checking %@ as a 'home page' URL candidate for this app.", redactedUrl];
            if (![self isReservedUrlValue:requestUrl]) {
                [SFSDKHybridLogger i:[self class] format:@"Setting %@ as the 'home page' URL for this app.", redactedUrl];
                self.appHomeUrl = requestUrl;
                _foundHomeUrl = YES;
            }
        }
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPageDidLoadNotification object:self.webView]];
    }
}

- (void) webView:(WKWebView *) webView didFailNavigation:(WKNavigation *) navigation withError:(NSError *) error
{
    if ([webView isEqual:self.webView]) {
        [SFSDKHybridLogger e:[self class] format:@"Error while attempting to load web page: %@", error];
        if ([[self class] isFatalWebViewError:error]) {
            [self loadErrorPageWithCode:[error code] description:[error localizedDescription] context:kErrorContextAppLoading];
        }
    }
}

+ (BOOL)isFatalWebViewError:(NSError *)error
{
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        return NO;
    }
    return YES;
}

- (BOOL)isReservedUrlValue:(NSURL *)url
{
    static NSArray *reservedUrlStrings = nil;
    if (reservedUrlStrings == nil) {
        reservedUrlStrings = @[@"/secur/frontdoor.jsp",
                               @"/secur/contentDoor"];
    }
    if (url == nil || [url absoluteString] == nil || [[url absoluteString] length] == 0) {
        return NO;    
    }
    NSString *inputUrlString = [url absoluteString];
    for (int i = 0; i < [reservedUrlStrings count]; i++) {
        NSString *reservedString = reservedUrlStrings[i];
        NSRange range = [[inputUrlString lowercaseString] rangeOfString:[reservedString lowercaseString]];
        if (range.location != NSNotFound)
            return YES;
    }
    return NO;
}

- (void)authenticationCompletion:(NSString *)originalUrl authInfo:(SFOAuthInfo *)authInfo
{
    [SFSDKHybridLogger i:[self class] format:@"[%@ %@]: Initiating post-auth configuration.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
    [self prepareWebState:^{
        if (originalUrl != nil) {
            [SFSDKHybridLogger i:[self class] format:@"[%@ %@]: Authentication complete. Loading '%@'.", NSStringFromClass([self class]), NSStringFromSelector(_cmd), originalUrl];
            NSURL *urlToLoad = [self absoluteUrlWithUrl:originalUrl];
            NSURLRequest *newRequest = [NSURLRequest requestWithURL:urlToLoad];
            [(WKWebView *)(self.webView) loadRequest:newRequest];
        }
    }];
}

- (void)refreshCredentialsWithCompletion:(nullable SFUserAccountManagerSuccessCallbackBlock)completionBlock
                                 failure:(nullable SFUserAccountManagerFailureCallbackBlock)failureBlock {

    /*
     * Performs a cheap REST call to refresh the access token if needed
     * instead of going through the entire OAuth dance all over again.
     */
    SFOAuthInfo *authInfo = [[SFOAuthInfo alloc] initWithAuthType:SFOAuthTypeRefresh];
    SFRestRequest *request = [[SFRestAPI sharedInstance] cheapRequest:nil];
    [[SFRestAPI sharedInstance] sendRequest:request failureBlock:^(id response, NSError *e, NSURLResponse *rawResponse) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(authInfo, e);
        });
    } successBlock:^(id response, NSURLResponse *rawResponse) {
        SFUserAccount *currentAccount = [SFUserAccountManager sharedInstance].currentUser;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(authInfo, currentAccount);
        });
    }];
}

@end

