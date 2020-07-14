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

- (NSURL *)frontDoorUrlWithReturnUrl:(NSString *)returnUrlString returnUrlIsEncoded:(BOOL)isEncoded createAbsUrl:(BOOL)createAbsUrl;

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
    NSURLComponents *components = [NSURLComponents componentsWithURL:[self.hybridViewController frontDoorUrlWithReturnUrl:@"apex/abc" returnUrlIsEncoded:NO createAbsUrl:YES] resolvingAgainstBaseURL:NO];
    NSString* expectedRetUrl = [NSString stringWithFormat:@"https://%@/apex/abc", components.host];
    XCTAssertEqualObjects(components.scheme, @"https", "Wrong scheme");
    XCTAssertEqualObjects(components.path, @"/secur/frontdoor.jsp", "Wrong path");
    XCTAssertEqualObjects(components.queryItems[0].name, @"sid");
    XCTAssertEqualObjects(components.queryItems[1].name, @"retURL");
    XCTAssertEqualObjects(components.queryItems[1].value, expectedRetUrl, "Wrong retUrl");
    XCTAssertEqualObjects(components.queryItems[2].name, @"display");
    XCTAssertEqualObjects(components.queryItems[2].value, @"touch");
}

- (void)testFrontDoorUrlWithLeadingSlash {
    NSURLComponents *components = [NSURLComponents componentsWithURL:[self.hybridViewController frontDoorUrlWithReturnUrl:@"/apex/abc" returnUrlIsEncoded:NO createAbsUrl:YES] resolvingAgainstBaseURL:NO];
    NSString* expectedRetUrl = [NSString stringWithFormat:@"https://%@/apex/abc", components.host];
    XCTAssertEqualObjects(components.scheme, @"https", "Wrong scheme");
    XCTAssertEqualObjects(components.path, @"/secur/frontdoor.jsp", "Wrong path");
    XCTAssertEqualObjects(components.queryItems[0].name, @"sid");
    XCTAssertEqualObjects(components.queryItems[1].name, @"retURL");
    XCTAssertEqualObjects(components.queryItems[1].value, expectedRetUrl, "Wrong retUrl");
    XCTAssertEqualObjects(components.queryItems[2].name, @"display");
    XCTAssertEqualObjects(components.queryItems[2].value, @"touch");
}


@end
