/*
 ViewController.m
 ViewController
 
 Copyright (c) 2018-present, salesforce.com, inc. All rights reserved.
 
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
#import "ViewController.h"
#import "Classes/AppDelegate.h"
#import <SalesforceFileLogger/SalesforceFileLogger.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Log some messages using SFSDKLogger without enabling OSLog
    [[SFSDKLogger sharedInstance] i:[self class] message:@"Info log message without OSLog"];
    [[SFSDKLogger sharedInstance] w:[self class] message:@"Warning log message without OSLog"];
    [[SFSDKLogger sharedInstance] e:[self class] message:@"Error log message without OSLog"];
    [[SFSDKLogger sharedInstance] d:[self class] message:@"Debug log message without OSLog"];
    
    [SFSDKLogger setUseOSLog:YES];
    
    // Create a new logger instance with OSLog enabled and log some more messages
    SFSDKLogger *osLogTestLogger = [SFSDKLogger sharedInstanceWithComponent:@"OSLog Test"];
    [osLogTestLogger i:[self class] message:@"Info log message with OSLog"];
    [osLogTestLogger w:[AppDelegate class] message:@"Warning log message with OSLog"];
    [osLogTestLogger e:[NSString class] message:@"Error log message with OSLog"];
    [osLogTestLogger d:[SFSDKLogger class] message:@"Debug log message with OSLog"];
}

@end
