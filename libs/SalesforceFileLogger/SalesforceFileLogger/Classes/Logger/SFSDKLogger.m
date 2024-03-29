/*
 SFSDKLogger.m
 SalesforceFileLogger
 
 Created by Bharath Hariharan on 6/8/17.
 
 Copyright (c) 2017-present, salesforce.com, inc. All rights reserved.
 
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

#import "SFSDKLogger.h"
#import <SalesforceSDKCommon/NSUserDefaults+SFAdditions.h>
#import <CocoaLumberjack/DDTTYLogger.h>

static NSString * const kDefaultComponentName = @"SFSDK";
static NSString * const kFileLoggerOnOffKey = @"file_logger_enabled";
static NSString * const kLogLevelKey = @"log_level";
static NSString * const kLogIdentifierFormat = @"COMPONENT: %@, CLASS: %@";
static NSMutableDictionary<NSString *, SFSDKLogger *> *loggerList = nil;

@interface SFSDKLogger ()

@property (nonatomic, readwrite, strong) NSString *componentName;
@property (nonatomic, readwrite, strong) DDLog *logger;
@end

@implementation SFSDKLogger

+ (instancetype)sharedInstanceWithComponent:(NSString *)componentName {
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        loggerList = [[NSMutableDictionary alloc] init];
    });
    @synchronized ([SFSDKLogger class]) {
        if (!componentName) {
            return nil;
        }
        id logger = loggerList[componentName];
        if (!logger) {
            logger = [[SFSDKLogger alloc] initWithComponent:componentName];
            loggerList[componentName] = logger;
        }
        return logger;
    }
}

+ (instancetype)sharedInstance {
    return [self sharedInstanceWithComponent:kDefaultComponentName];
}

+ (void)flushAllComponents:(void (^)(void))completionBlock {
    @synchronized ([SFSDKLogger class]) {
        __block NSUInteger numberOfLogsLeftToFlush = loggerList.allKeys.count;
        for (NSString *loggerKey in loggerList.allKeys) {
            [loggerList[loggerKey].fileLogger flushLogWithCompletionBlock:^{
                numberOfLogsLeftToFlush--;
                if (numberOfLogsLeftToFlush ==0 && completionBlock) {
                    completionBlock();
                }
            }];
        }
        [loggerList removeAllObjects];
    }
}

+ (NSArray<NSString *> *)allComponents {
    @synchronized ([SFSDKLogger class]) {
        return loggerList.allKeys;
    }
}

- (instancetype)initWithComponent:(NSString *)componentName {
    self = [super init];
    if (self) {
        self.componentName = componentName;
        self.logger = [[DDLog alloc] init];
        self.fileLogger = [[SFSDKFileLogger alloc] initWithComponent:componentName];
        DDTTYLogger *consoleLogger = [DDTTYLogger sharedInstance];
        consoleLogger.logFormatter = [[SFSDKFormatter alloc] init];
        consoleLogger.colorsEnabled = YES;
        [self.logger addLogger:consoleLogger withLevel:DDLogLogLevelForSFLogLevel(self.logLevel)];
        if (self.fileLoggingEnabled) {
            [self.logger addLogger:self.fileLogger withLevel:DDLogLogLevelForSFLogLevel(self.logLevel)];
        }
    }
    return self;
}

- (void)setFileLogger:(SFSDKFileLogger *)fileLogger {
    if (fileLogger != _fileLogger) {
        if (self.isFileLoggingEnabled) {
            [_logger removeLogger:_fileLogger];
            [_logger addLogger:fileLogger withLevel:DDLogLogLevelForSFLogLevel(self.logLevel)];
        }
        _fileLogger = fileLogger;
    }
}

- (void)setFileLoggingEnabled:(BOOL)loggingEnabled {
    BOOL curPolicy = [self readFileLoggingPolicy];
    [self storeFileLoggingPolicy:loggingEnabled];
    BOOL newPolicy = [self readFileLoggingPolicy];

    // Adds or removes the file logger depending on the change in policy.
    if (curPolicy != newPolicy) {
        if (newPolicy) {
            [self.logger addLogger:self.fileLogger withLevel:DDLogLogLevelForSFLogLevel(self.logLevel)]; // Disabled to enabled.
        } else {
            [self.logger removeLogger:self.fileLogger]; // Enabled to disabled.
        }
    }
}

- (BOOL)isFileLoggingEnabled {
    return [self readFileLoggingPolicy];
}

- (SFLogLevel)logLevel {
   return SFLogLevelForDDLogLogLevel(self.ddLogLevel);
}

- (void)setLogLevel:(SFLogLevel)sfLogLevel {
    DDLogLevel logLevel = DDLogLogLevelForSFLogLevel(sfLogLevel);
    self.ddLogLevel = logLevel;
}

- (DDLogLevel)ddLogLevel {
     return [self readLogLevel];
}

- (void)setDdLogLevel:(DDLogLevel)logLevel {
    [self storeLogLevel:logLevel];
    [self.logger removeAllLoggers];
    DDTTYLogger *consoleLogger = [DDTTYLogger sharedInstance];
    consoleLogger.colorsEnabled = YES;
    [self.logger addLogger:consoleLogger withLevel:logLevel];
    [self.logger addLogger:self.fileLogger withLevel:logLevel];
}

- (void)e:(Class)cls format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self log:cls level:SFLogLevelError format:format args:args];
    va_end(args);
}

- (void)e:(Class)cls message:(NSString *)message {
    [self log:cls level:SFLogLevelError message:message];
}

- (void)w:(Class)cls format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self logInternal:cls level:DDLogLevelWarning format:format args:args];
    va_end(args);
}

- (void)w:(Class)cls message:(NSString *)message {
    [self logInternal:cls level:DDLogLevelWarning message:message];
}

- (void)i:(Class)cls format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self log:cls level:SFLogLevelInfo format:format args:args];
    va_end(args);
}

- (void)i:(Class)cls message:(NSString *)message {
    [self log:cls level:SFLogLevelInfo message:message];
}

- (void)v:(Class)cls format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self logInternal:cls level:DDLogLevelVerbose format:format args:args];
    va_end(args);
}

- (void)v:(Class)cls message:(NSString *)message {
    [self logInternal:cls level:DDLogLevelVerbose message:message];
}

- (void)d:(Class)cls format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self log:cls level:SFLogLevelDebug format:format args:args];
    va_end(args);
}

- (void)d:(Class)cls message:(NSString *)message {
    [self log:cls level:SFLogLevelDebug message:message];
}

- (void)logInternal:(Class)cls level:(DDLogLevel)level message:(NSString *)message  {
    NSString *tag = [NSString stringWithFormat:kLogIdentifierFormat, self.componentName, cls];
    DDLogMessage *logMessage = [[DDLogMessage alloc] initWithFormat:message formatted:message level:level flag:DDLogFlagForLogLevel(level) context:0 file:self.componentName function:nil line:0 tag:tag options:0 timestamp:[NSDate date]];
    [self.logger log:YES message:logMessage];
}

- (void)logInternal:(Class)cls level:(DDLogLevel)level format:(NSString *)format args:(va_list)args {
    NSString *formattedMessage = [[NSString alloc] initWithFormat:format arguments:args];
    [self logInternal:cls level:level message:formattedMessage];
}

- (void)log:(Class)cls level:(SFLogLevel)level message:(NSString *)message {
    [self logInternal:cls level:DDLogLogLevelForSFLogLevel(level) message:message];
}

- (void)log:(Class)cls level:(SFLogLevel)level format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self log:cls level:level format:format args:args];
    va_end(args);
}

- (void)log:(Class)cls level:(SFLogLevel)level format:(NSString *)format args:(va_list)args {
   [self logInternal:cls level:DDLogLogLevelForSFLogLevel(level) format:format args:args];
}

- (void)storeFileLoggingPolicy:(BOOL)enabled {
    @synchronized (self) {
        NSUserDefaults *defs = [NSUserDefaults msdkUserDefaults];
        [defs setBool:enabled forKey:kFileLoggerOnOffKey];
        [defs synchronize];
    }
}

- (BOOL)readFileLoggingPolicy {
    BOOL fileLoggingEnabled;
    NSNumber *fileLoggingEnabledNum = [[NSUserDefaults msdkUserDefaults] objectForKey:kFileLoggerOnOffKey];
    if (fileLoggingEnabledNum == nil) {

        // Default is enabled.
        fileLoggingEnabled = YES;
        [self storeFileLoggingPolicy:fileLoggingEnabled];
    } else {
        fileLoggingEnabled = [fileLoggingEnabledNum boolValue];
    }
    return fileLoggingEnabled;
}

- (void)storeLogLevel:(DDLogLevel)logLevel {
    @synchronized (self) {
        NSUserDefaults *defs = [NSUserDefaults msdkUserDefaults];
        [defs setInteger:logLevel forKey:kLogLevelKey];
        [defs synchronize];
    }
}

- (DDLogLevel)readLogLevel {
    DDLogLevel logLevel;
    if ([[[[NSUserDefaults msdkUserDefaults] dictionaryRepresentation] allKeys] containsObject:kLogLevelKey]) {
        logLevel = [[NSUserDefaults msdkUserDefaults] integerForKey:kLogLevelKey];
    } else {
        logLevel = DDLogLevelError;
#ifdef DEBUG
        logLevel = DDLogLevelDebug;
#endif
        [self storeLogLevel:logLevel];
    }
    return logLevel;
}

static inline DDLogFlag DDLogFlagForLogLevel(DDLogLevel level) {
    switch (level) {
        case DDLogLevelError:
            return DDLogFlagError;
        case DDLogLevelWarning:
            return DDLogFlagWarning;
        case DDLogLevelInfo:
            return DDLogFlagInfo;
        case DDLogLevelVerbose:
            return DDLogFlagVerbose;
        case DDLogLevelDebug:
        default:
            return DDLogFlagDebug;
    }
}

static inline DDLogLevel DDLogLogLevelForSFLogLevel(SFLogLevel level) {
    switch (level) {
        case SFLogLevelError:
            return DDLogLevelError;
        case SFLogLevelFault:
            return DDLogLevelError;
        case SFLogLevelInfo:
            return DDLogLevelInfo;
        case SFLogLevelDefault:
            return DDLogLevelVerbose;
        default:
            return DDLogLevelDebug;
    }
}

static inline SFLogLevel SFLogLevelForDDLogLogLevel(DDLogLevel level) {
    switch (level) {
        case DDLogLevelError:
            return SFLogLevelError;
        case DDLogLevelInfo:
            return SFLogLevelInfo;
        case DDLogLevelVerbose:
            return SFLogLevelDefault;
        case DDLogLevelDebug:
            return SFLogLevelDebug;
        default:
            return SFLogLevelDebug;
    }
}


#pragma mark - Class-level convenience methods

+ (DDLogLevel)logLevel {
     return ((SFSDKLogger *)[self sharedInstance]).ddLogLevel;
}

+ (void)setLogLevel:(DDLogLevel)logLevel {
    ((SFSDKLogger *)[self sharedInstance]).ddLogLevel = logLevel;
}

+ (void)e:(Class)cls format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [[self sharedInstance] logInternal:cls level:DDLogLevelError format:format args:args];
    va_end(args);
}

+ (void)e:(Class)cls message:(NSString *)message {
    [[self sharedInstance] logInternal:cls level:DDLogLevelError message:message];
}

+ (void)w:(Class)cls format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [[self sharedInstance] logInternal:cls level:DDLogLevelWarning format:format args:args];
    va_end(args);
}

+ (void)w:(Class)cls message:(NSString *)message {
    [[self sharedInstance] logInternal:cls level:DDLogLevelWarning message:message];
}

+ (void)i:(Class)cls format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [[self sharedInstance] logInternal:cls level:DDLogLevelInfo format:format args:args];
    va_end(args);
}

+ (void)i:(Class)cls message:(NSString *)message {
    [[self sharedInstance] logInternal:cls level:DDLogLevelInfo message:message];
}

+ (void)v:(Class)cls format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [[self sharedInstance] logInternal:cls level:DDLogLevelVerbose format:format args:args];
    va_end(args);
}

+ (void)v:(Class)cls message:(NSString *)message {
    [[self sharedInstance] logInternal:cls level:DDLogLevelVerbose message:message];
}

+ (void)d:(Class)cls format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [[self sharedInstance] logInternal:cls level:DDLogLevelDebug format:format args:args];
    va_end(args);
}

+ (void)d:(Class)cls message:(NSString *)message {
    [[self sharedInstance] logInternal:cls level:DDLogLevelDebug message:message];
}

+ (void)log:(Class)cls level:(DDLogLevel)level format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [[self sharedInstance] logInternal:cls level:level format:format args:args];
    va_end(args);
}

+ (void)log:(Class)cls level:(DDLogLevel)level message:(NSString *)message {
    [[self sharedInstance] logInternal:cls level:level message:message];
}

@end

#pragma mark - Log formatter for console logs

@implementation SFSDKFormatter

- (instancetype)init {
    return [self initWithDateFormatter:nil];
}

- (instancetype)initWithDateFormatter: (NSDateFormatter *)specialFormatter {
    self = [super init];
    if (self) {
        if (specialFormatter == nil) {
            self.dateFormatter = [[NSDateFormatter alloc] init];
            [self.dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
            [self.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSZ"];
        } else {
            self.dateFormatter = specialFormatter;
        }
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    NSString *date = [self.dateFormatter stringFromDate:logMessage.timestamp];
    return [NSString stringWithFormat:@"%@ %@[%d:%@] %@", date, appName, (int)getpid(), [logMessage threadID], logMessage.message];
}

@end
