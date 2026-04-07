[![Tests](https://github.com/forcedotcom/SalesforceMobileSDK-iOS-Hybrid/actions/workflows/nightly.yaml/badge.svg)](https://github.com/forcedotcom/SalesforceMobileSDK-iOS-Hybrid/actions/workflows/nightly.yaml)

# Salesforce Mobile SDK for iOS Hybrid

iOS native bridge layer and libraries for Cordova-based hybrid mobile applications.

## Overview

This repository provides the **iOS native implementation** for hybrid apps built with the Salesforce Mobile SDK and Apache Cordova. It bridges JavaScript Cordova plugins to iOS native SDK functionality, enabling hybrid apps to leverage authentication, SmartStore, MobileSync, and REST APIs.

### What's Included

- **SalesforceHybridSDK**: Cordova plugin bridges and hybrid view management
- **SalesforceFileLogger**: File-based logging for hybrid apps
- **Sample Apps**: Demo applications showcasing SDK features
- **Dependencies**: iOS SDK, Cordova, and CocoaLumberjack as submodules

## Architecture

```
Hybrid App (HTML/JS/CSS)
        ↓
Cordova Plugins (JavaScript)
        ↓
SalesforceHybridSDK (iOS Bridge - this repo)
        ↓
iOS Mobile SDK (Native)
        ↓
Salesforce Platform
```

## Getting Started

### For New Hybrid Apps

We recommend using the [forcehybrid](https://npmjs.org/package/forcehybrid) command-line tool to create hybrid apps:

```bash
# Install CLI tools
npm install -g forcehybrid

# Create a new hybrid app
forcehybrid create
    --platform ios
    --appname MyHybridApp
    --packagename com.mycompany.myhybridapp
    --organization "My Company"
```

This creates a complete Cordova-based hybrid app with the Salesforce Mobile SDK pre-configured.

### For SDK Development

If you want to work with the iOS Hybrid SDK source code:

**Prerequisites**:
- macOS with Xcode 15+
- Git (for submodule management)
- CocoaPods

**Setup**:
```bash
# Clone the repository
git clone https://github.com/forcedotcom/SalesforceMobileSDK-iOS-Hybrid.git
cd SalesforceMobileSDK-iOS-Hybrid

# Pull submodule dependencies
./install.sh

# Open the workspace
open SalesforceMobileSDK-Hybrid.xcworkspace
```

**Important**: Always open the `.xcworkspace` file, not individual `.xcodeproj` files.

## Repository Structure

### Libraries (`libs/`)

**SalesforceHybridSDK**
- Main hybrid bridge library
- Cordova plugin implementations (OAuth, SmartStore, MobileSync, Network, SDKInfo)
- Hybrid view controller and configuration
- WKWebView cookie management
- Minimum iOS: 18.0

**SalesforceFileLogger**
- File-based logging with rotation
- Integration with CocoaLumberjack
- Log export for debugging

### Sample Apps (`hybrid/SampleApps/`)

**AccountEditor**
- Basic CRUD operations on Account records
- Demonstrates Cordova plugin usage
- Local hybrid app example

**MobileSyncExplorerHybrid**
- Complete MobileSync demo
- Offline data synchronization
- SmartStore integration
- Conflict resolution

### Dependencies (`external/`)

Git submodules for core dependencies:
- **SalesforceMobileSDK-iOS**: iOS native SDK
- **shared**: Shared JavaScript libraries (SalesforceMobileSDK-Shared)
- **cordova**: Apache Cordova for iOS
- **CocoaLumberjack**: Logging framework

## Key Features

### Cordova Plugin Bridges

Native iOS implementations of Salesforce Cordova plugins:

| Plugin | Purpose |
|--------|---------|
| **OAuth** | Authentication, login, logout, user management |
| **SmartStore** | Encrypted local storage (SQLCipher-backed) |
| **MobileSync** | Bidirectional data synchronization |
| **Network** | REST API requests to Salesforce |
| **SDKInfo** | SDK version and configuration information |
| **AccountManager** | Multi-user account management |

### Hybrid View Management

- **SFHybridViewController**: Manages Cordova WebView lifecycle
- **SFHybridViewConfig**: Configures local vs remote app behavior
- **Cookie Management**: Shares Salesforce sessions between native and WebView
- **Authentication Flow**: Handles OAuth before loading app content

## Development

### Building from Source

```bash
# Build the library
xcodebuild -workspace SalesforceMobileSDK-Hybrid.xcworkspace \
  -scheme SalesforceHybridSDK \
  -sdk iphonesimulator \
  build

# Run tests
xcodebuild test -workspace SalesforceMobileSDK-Hybrid.xcworkspace \
  -scheme SalesforceHybridSDK \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Running Sample Apps

1. Open `SalesforceMobileSDK-Hybrid.xcworkspace`
2. Select `AccountEditor` or `MobileSyncExplorerHybrid` scheme
3. Choose a simulator or device
4. Build and run (Cmd+R)

### Testing

**Unit Tests**: Located in `libs/SalesforceHybridSDK/SalesforceHybridSDKTests/`
- Test Cordova plugin bridges
- Test hybrid view configuration
- Test cookie management

**Integration Tests**: Sample apps serve as integration tests
- Verify end-to-end plugin functionality
- Test authentication flows
- Validate data synchronization

## API Overview

### JavaScript (in Hybrid App)

```javascript
// After including cordova.js and cordova.force.js

// OAuth - Get current user
navigator.oauth.getAuthCredentials(
    function(creds) {
        console.log('User:', creds.userName);
    },
    function(error) {
        console.error('Auth error:', error);
    }
);

// SmartStore - Query data
navigator.smartstore.querySoup(
    false, // isGlobalStore
    'accounts',
    querySpec,
    function(results) {
        console.log('Found:', results.totalEntries, 'entries');
    },
    function(error) {
        console.error('Query error:', error);
    }
);

// Network - REST API call
com.salesforce.plugin.network.sendRequest(
    '/services/data/v56.0/query/',
    'SELECT Id, Name FROM Account LIMIT 10',
    function(response) {
        console.log('Accounts:', response.records);
    },
    function(error) {
        console.error('API error:', error);
    }
);
```

### Native iOS (Plugin Implementation)

```objective-c
// Example: Implementing a Cordova plugin
@interface MyPlugin : CDVPlugin

- (void)myMethod:(CDVInvokedUrlCommand*)command;

@end

@implementation MyPlugin

- (void)myMethod:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        // Do work
        NSString* result = @"Success";

        CDVPluginResult* pluginResult = [CDVPluginResult
            resultWithStatus:CDVCommandStatus_OK
            messageAsString:result];

        [self.commandDelegate sendPluginResult:pluginResult
            callbackId:command.callbackId];
    }];
}

@end
```

## Version Compatibility

| iOS Hybrid SDK | iOS SDK | Cordova iOS | iOS Min | Xcode |
|---------------|---------|-------------|---------|-------|
| 13.2.0        | 13.2.0  | 7.1.1       | 17.0    | 15+   |
| 13.1.0        | 13.1.0  | 7.1.0       | 16.0    | 15+   |
| 13.0.0        | 13.0.0  | 7.1.0       | 16.0    | 15+   |

See [release notes](https://github.com/forcedotcom/SalesforceMobileSDK-iOS-Hybrid/releases) for detailed version history.

## Distribution

### CocoaPods

The SalesforceHybridSDK library is distributed via CocoaPods:

```ruby
pod 'SalesforceHybridSDK', '~> 13.2'
```

**Note**: Typically installed automatically by the Cordova plugin, not added directly.

### Cordova Plugin

This repo provides the iOS implementation consumed by the [SalesforceMobileSDK-CordovaPlugin](https://github.com/forcedotcom/SalesforceMobileSDK-CordovaPlugin) package.

## Documentation

### Developer Resources
- **Mobile SDK Development Guide**: https://developer.salesforce.com/docs/platform/mobile-sdk/guide
- **iOS SDK Documentation**: https://forcedotcom.github.io/SalesforceMobileSDK-iOS
- **Mobile SDK Trail**: https://trailhead.salesforce.com/trails/mobile_sdk_intro
- **Cordova Documentation**: https://cordova.apache.org/docs/

### Related Repositories
- **iOS SDK** (native): https://github.com/forcedotcom/SalesforceMobileSDK-iOS
- **Android Hybrid**: https://github.com/forcedotcom/SalesforceMobileSDK-Android (libs/SalesforceHybrid)
- **Shared JavaScript**: https://github.com/forcedotcom/SalesforceMobileSDK-Shared
- **Cordova Plugin**: https://github.com/forcedotcom/SalesforceMobileSDK-CordovaPlugin
- **Templates**: https://github.com/forcedotcom/SalesforceMobileSDK-Templates

## Support

- **Issues**: [GitHub Issues](https://github.com/forcedotcom/SalesforceMobileSDK-iOS-Hybrid/issues)
- **Questions**: [Salesforce Stack Exchange](https://salesforce.stackexchange.com/questions/tagged/mobilesdk)
- **Community**: [Trailblazer Community](https://trailhead.salesforce.com/trailblazer-community/groups/0F94S000000kH0HSAU)

## Contributing

We welcome contributions! Please:
1. Read the [CLAUDE.md](CLAUDE.md) file for development guidelines
2. Follow existing code style and conventions
3. Write or update tests for new functionality
4. Test on iOS devices and simulators
5. Ensure changes are compatible with Android hybrid implementation
6. Submit a pull request with a clear description

### Before Submitting
- Run unit tests for SalesforceHybridSDK
- Build and test sample apps (AccountEditor, MobileSyncExplorerHybrid)
- Verify no Xcode warnings or errors
- Test with hybrid templates if changing public APIs

## License

Salesforce Mobile SDK License. See [LICENSE](LICENSE) file for details.

## Security

Please report security vulnerabilities to [security@salesforce.com](mailto:security@salesforce.com). See [SECURITY.md](SECURITY.md) for more information.
