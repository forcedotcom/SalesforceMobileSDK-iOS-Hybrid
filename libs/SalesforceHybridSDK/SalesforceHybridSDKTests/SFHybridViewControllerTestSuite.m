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

@interface SFHybridViewController (tests)

- (NSURL *)absoluteUrlWithUrl:(NSString *)url;
- (NSString *)isLoginRedirectUrl:(NSURL *)url;
- (BOOL)isVFPageRedirect:(NSURL *)url;
- (void)configureRemoteStartPage;

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


@end
