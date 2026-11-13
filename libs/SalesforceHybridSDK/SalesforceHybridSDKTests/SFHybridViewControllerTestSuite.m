/*
 Copyright (c) 2020-present, salesforce.com, inc. All rights reserved.
 
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

#import <XCTest/XCTest.h>
#import "SFHybridViewConfig.h"
#import "SFHybridViewController.h"
#import <Cordova/NSDictionary+CordovaPreferences.h>

@interface SFHybridViewController (tests)

- (NSURL *)absoluteUrlWithUrl:(NSString *)url;
- (NSString *)isLoginRedirectUrl:(NSURL *)url;
- (BOOL)isVFPageRedirect:(NSURL *)url;
- (void)configureRemoteStartPage;
- (void)loadSettings;

@end

@interface SFHybridCustomUIDelegateController : SFHybridViewController <WKUIDelegate>
@property (nonatomic, copy) NSString *lastAlertMessage;
@property (nonatomic, strong) WKWebView *providedWindow;
@end
@implementation SFHybridCustomUIDelegateController
- (void)webView:(WKWebView *)webView
    runJavaScriptAlertPanelWithMessage:(NSString *)message
    initiatedByFrame:(WKFrameInfo *)frame
    completionHandler:(void (^)(void))completionHandler {
    self.lastAlertMessage = message;
    completionHandler();
}
- (WKWebView *)webView:(WKWebView *)webView
    createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
    forNavigationAction:(WKNavigationAction *)action
    windowFeatures:(WKWindowFeatures *)features {
    return self.providedWindow;
}
- (void)webViewDidClose:(WKWebView *)webView {
    self.lastAlertMessage = @"closed";
}
@end

@interface SFHybridDialogController : SFHybridViewController
@property (nonatomic, strong) UIAlertController *capturedAlert;
@property (nonatomic, copy) NSString *mediaPermissionPreference;
@end
@implementation SFHybridDialogController
- (void)loadSettings {
    [super loadSettings];
    if (self.mediaPermissionPreference) {
        [self.settings setCordovaSetting:self.mediaPermissionPreference
            forKey:@"MediaPermissionGrantType"];
    }
}
- (void)presentViewController:(UIViewController *)controller
                    animated:(BOOL)animated
                  completion:(void (^)(void))completion {
    self.capturedAlert = (UIAlertController *)controller;
    if (completion) {
        completion();
    }
}
@end

@interface SFHybridViewControllerTestSuite : XCTestCase

@property (nonnull, nonatomic, strong) SFHybridViewConfig *hybridViewConfig;
@property (nonnull, nonatomic, strong) SFHybridViewController *hybridViewController;

@end

@implementation SFHybridViewControllerTestSuite

- (void)setUp {
    [super setUp];
    self.hybridViewConfig = [[SFHybridViewConfig alloc] init];
    self.hybridViewConfig.remoteAccessConsumerKey = @"testConsumerKey";
    self.hybridViewConfig.oauthRedirectURI = @"test:///redirectUri";
    self.hybridViewConfig.oauthScopes = [NSSet setWithArray:@[ @"web", @"api" ]];
    self.hybridViewController = [[SFHybridViewController alloc] initWithConfig:self.hybridViewConfig];
}

- (void)testFrontDoorUrlNoLeadingSlash {
    NSString* expectedSubstring = @"SalesforceHybridSDKTestApp/1.0(1.0) HybridLocal";
    XCTAssertTrue([self.hybridViewController.sfHybridViewUserAgentString containsString:expectedSubstring],
                      @"User agent string should contain 'HybridLocal'");
    self.hybridViewConfig.isLocal = false;
    expectedSubstring = @"SalesforceHybridSDKTestApp/1.0(1.0) HybridRemote";
    XCTAssertTrue([self.hybridViewController.sfHybridViewUserAgentString containsString:expectedSubstring],
                      @"User agent string should contain 'HybridRemote'");
}

- (void)testAbsoluteUrlWithRelativeUrl{
    NSString* actualUrl = [self.hybridViewController absoluteUrlWithUrl:@"/apex/abc"].absoluteString;
    NSString* expectedUrl = [NSString stringWithFormat:@"%@%@", [SFUserAccountManager sharedInstance].currentUser.credentials.instanceUrl.absoluteString, @"/apex/abc"];
    XCTAssertEqualObjects(actualUrl, expectedUrl);
}

- (void)testAbsoluteUrlWithFullUrl{
    NSString* actualUrl = [self.hybridViewController absoluteUrlWithUrl:@"https://abc.com/def"].absoluteString;
    NSString* expectedUrl = @"https://abc.com/def";
    XCTAssertEqualObjects(actualUrl, expectedUrl);
}

- (void)testIsVFPageRedirect{
    XCTAssertTrue([self.hybridViewController isVFPageRedirect:[NSURL URLWithString:@"https://xyz.com?ec=301"]]);
    XCTAssertTrue([self.hybridViewController isVFPageRedirect:[NSURL URLWithString:@"https://xyz.com?ec=302"]]);
    XCTAssertFalse([self.hybridViewController isVFPageRedirect:[NSURL URLWithString:@"https://xyz.com?ec=something-else"]]);
}

- (void)testIsLoginUrlWithNonLoginUrl{
    NSURL* url = [NSURL URLWithString:@"https://xyz.com/apex/abc"];
    XCTAssertNil([self.hybridViewController isLoginRedirectUrl:url]);
}

- (void)testIsLoginUrlWithVfRedirect{
    // vf redirect url with retURL
    XCTAssertEqualObjects([self.hybridViewController isLoginRedirectUrl:[NSURL URLWithString:@"https://xyz.com?ec=302&retURL=%2Fapex%2Fabc"]], @"/apex/abc");
    // vf redirect url with startURL
    XCTAssertEqualObjects([self.hybridViewController isLoginRedirectUrl:[NSURL URLWithString:@"https://xyz.com?ec=302&startURL=%2Fapex%2Fabc"]], @"/apex/abc");
}

- (void)testIsLoginUrlWithVfRedirectNoRetUrl{
    // vf redirect url without startURL
    self.hybridViewConfig.isLocal = false;
    self.hybridViewConfig.startPage = @"apex/def";
    [self.hybridViewController configureRemoteStartPage];
    NSString* expectedUrl = [NSString stringWithFormat:@"%@%@", [SFUserAccountManager sharedInstance].currentUser.credentials.instanceUrl.absoluteString, @"/apex/def"];
    XCTAssertEqualObjects([self.hybridViewController isLoginRedirectUrl:[NSURL URLWithString:@"https://xyz.com?ec=302"]], expectedUrl);
}

- (void)testConfigureRemoteStartPage{
    self.hybridViewConfig.isLocal = false;
    self.hybridViewConfig.startPage = @"apex/def";
    [self.hybridViewController configureRemoteStartPage];
    NSString* expectedUrl = [NSString stringWithFormat:@"%@%@", [SFUserAccountManager sharedInstance].currentUser.credentials.instanceUrl.absoluteString, @"/apex/def"];
    XCTAssertEqualObjects(self.hybridViewController.startPage, expectedUrl);
}


- (void)test_givenLocalUnauthenticatedView_whenLoaded_thenRetainsDefaultUIDelegate {
    self.hybridViewConfig.isLocal = YES;
    self.hybridViewConfig.shouldAuthenticate = NO;
    self.hybridViewConfig.startPage = @"index.html";
    [self.hybridViewController loadViewIfNeeded];

    WKWebView *webView = (WKWebView *)self.hybridViewController.webView;
    XCTAssertNotNil(webView);
    XCTAssertNotNil(webView.UIDelegate);
    id engineDelegate = [(NSObject *)self.hybridViewController.webViewEngine
        valueForKey:@"uiDelegate"];
    XCTAssertNotNil(engineDelegate);
    XCTAssertEqual(engineDelegate, webView.UIDelegate);
    XCTAssertTrue([webView.UIDelegate respondsToSelector:
        @selector(webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:)]);
    XCTAssertTrue([webView.UIDelegate respondsToSelector:
        @selector(webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:)]);
    XCTAssertTrue([webView.UIDelegate respondsToSelector:
        @selector(webView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:)]);
}

- (void)test_givenCustomUIDelegate_whenLoaded_thenForwardsControllerDelegate {
    self.hybridViewConfig.isLocal = YES;
    self.hybridViewConfig.shouldAuthenticate = NO;
    SFHybridCustomUIDelegateController *controller =
        [[SFHybridCustomUIDelegateController alloc] initWithConfig:self.hybridViewConfig];
    [controller loadViewIfNeeded];

    WKWebView *webView = (WKWebView *)controller.webView;
    id<WKUIDelegate> delegate = webView.UIDelegate;
    XCTAssertNotNil(delegate);
    XCTAssertNotEqual(delegate, controller);
    XCTAssertTrue([delegate respondsToSelector:
        @selector(webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:)]);
    XCTAssertFalse([delegate respondsToSelector:
        @selector(webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:)]);
    __block BOOL completed = NO;
    WKFrameInfo *frame = nil;
    [delegate webView:webView runJavaScriptAlertPanelWithMessage:@"Custom alert"
        initiatedByFrame:frame completionHandler:^{ completed = YES; }];
    XCTAssertEqualObjects(controller.lastAlertMessage, @"Custom alert");
    XCTAssertTrue(completed);
    controller.providedWindow = [[WKWebView alloc] init];
    WKNavigationAction *action = nil;
    WKWindowFeatures *features = nil;
    XCTAssertEqual([delegate webView:webView
        createWebViewWithConfiguration:controller.providedWindow.configuration
        forNavigationAction:action windowFeatures:features], controller.providedWindow);
    [(CDVPlugin *)controller.webViewEngine dispose];
}

- (void)test_givenCustomUIDelegate_whenControllerReleased_thenDeallocates {
    __weak SFHybridViewController *releasedController;
    id<CDVWebViewEngineProtocol> engine;
    id<WKUIDelegate> delegate;
    @autoreleasepool {
        self.hybridViewConfig.isLocal = YES;
        self.hybridViewConfig.shouldAuthenticate = NO;
        SFHybridCustomUIDelegateController *controller =
            [[SFHybridCustomUIDelegateController alloc] initWithConfig:self.hybridViewConfig];
        [controller loadViewIfNeeded];
        engine = controller.webViewEngine;
        id<WKUIDelegate> installedDelegate = ((WKWebView *)controller.webView).UIDelegate;
        if (installedDelegate != controller) {
            delegate = installedDelegate;
        }
        releasedController = controller;
    }

    NSPredicate *deallocated = [NSPredicate predicateWithBlock:
        ^BOOL(id object, NSDictionary *bindings) {
            return releasedController == nil;
        }];
    XCTestExpectation *expectation = [[XCTNSPredicateExpectation alloc]
        initWithPredicate:deallocated object:nil];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:2];
    XCTAssertEqual(result, XCTWaiterResultCompleted);
    XCTAssertFalse([delegate respondsToSelector:@selector(webViewDidClose:)]);
    WKWebView *webView = nil;
    XCTAssertNoThrow([delegate webViewDidClose:webView]);
    [(CDVPlugin *)engine dispose];
}

- (void)test_givenDefaultUIDelegate_whenDialogsRequested_thenPresentsCordovaDialogs {
    self.hybridViewConfig.isLocal = YES;
    self.hybridViewConfig.shouldAuthenticate = NO;
    SFHybridDialogController *controller =
        [[SFHybridDialogController alloc] initWithConfig:self.hybridViewConfig];
    [controller loadViewIfNeeded];
    WKWebView *webView = (WKWebView *)controller.webView;
    id<WKUIDelegate> delegate = webView.UIDelegate;
    XCTAssertNotNil(delegate);
    WKFrameInfo *frame = nil;

    [delegate webView:webView runJavaScriptAlertPanelWithMessage:@"Alert message"
        initiatedByFrame:frame completionHandler:^{}];
    XCTAssertEqualObjects(controller.capturedAlert.message, @"Alert message");
    XCTAssertEqual(controller.capturedAlert.actions.count, 1u);

    [delegate webView:webView runJavaScriptConfirmPanelWithMessage:@"Confirm message"
        initiatedByFrame:frame completionHandler:^(BOOL confirmed) {}];
    XCTAssertEqualObjects(controller.capturedAlert.message, @"Confirm message");
    XCTAssertEqual(controller.capturedAlert.actions.count, 2u);

    [delegate webView:webView runJavaScriptTextInputPanelWithPrompt:@"Prompt message"
        defaultText:@"Initial text" initiatedByFrame:frame
        completionHandler:^(NSString *text) {}];
    XCTAssertEqualObjects(controller.capturedAlert.message, @"Prompt message");
    XCTAssertEqualObjects(controller.capturedAlert.textFields.firstObject.text,
        @"Initial text");
    XCTAssertEqual(controller.capturedAlert.actions.count, 2u);
}

- (void)test_givenDeniedMediaPreference_whenPermissionRequested_thenDeniesCapture {
    self.hybridViewConfig.isLocal = YES;
    self.hybridViewConfig.shouldAuthenticate = NO;
    SFHybridDialogController *controller =
        [[SFHybridDialogController alloc] initWithConfig:self.hybridViewConfig];
    controller.mediaPermissionPreference = @"deny";
    [controller loadViewIfNeeded];
    WKWebView *webView = (WKWebView *)controller.webView;
    XCTAssertNotNil(webView.UIDelegate);
    __block BOOL completed = NO;
    WKSecurityOrigin *origin = nil;
    WKFrameInfo *frame = nil;
    [webView.UIDelegate webView:webView
        requestMediaCapturePermissionForOrigin:origin initiatedByFrame:frame
        type:WKMediaCaptureTypeCamera decisionHandler:^(WKPermissionDecision decision) {
            XCTAssertEqual(decision, WKPermissionDecisionDeny);
            completed = YES;
        }];
    XCTAssertTrue(completed);
}

@end
