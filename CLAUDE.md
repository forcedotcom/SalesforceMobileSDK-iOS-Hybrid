# CLAUDE.md — Salesforce Mobile SDK for iOS Hybrid

---

## About This Project

The Salesforce Mobile SDK for iOS Hybrid provides the **iOS native bridge layer** for Cordova-based hybrid applications. It bridges JavaScript Cordova plugins to the iOS native Mobile SDK libraries, enabling hybrid apps to leverage full native SDK functionality.

**Key constraint**: This is a **public SDK**. Every change is visible to external developers. Backward compatibility, deprecation cycles, and semver discipline are non-negotiable.

## iOS Hybrid Architecture

```
Hybrid App (HTML/JS/Cordova)
  └── Cordova Plugins (from Shared repo)
       └── SalesforceHybridSDK (this repo)
            ├── Cordova Plugin Bridges (Objective-C)
            │   ├── SalesforceOAuthPlugin
            │   ├── SFSmartStorePlugin
            │   ├── SFMobileSyncPlugin
            │   ├── SFNetworkPlugin
            │   └── SFSDKInfoPlugin
            │
            ├── Hybrid View Management
            │   ├── SFHybridViewController
            │   ├── SFHybridViewConfig
            │   └── SalesforceWebViewCookieManager
            │
            └── iOS Native SDK (dependencies)
                 ├── MobileSync
                 ├── SmartStore
                 ├── SalesforceSDKCore
                 ├── SalesforceAnalytics
                 └── SalesforceSDKCommon
```

## Repository Structure

Workspace: `SalesforceMobileSDK-Hybrid.xcworkspace`

```
SalesforceMobileSDK-iOS-Hybrid/
├── libs/
│   ├── SalesforceHybridSDK/          # Main hybrid bridge library
│   │   ├── SalesforceHybridSDK/      # Library code
│   │   │   ├── Classes/
│   │   │   │   ├── Plugins/          # Cordova plugin implementations
│   │   │   │   ├── SFHybridViewController.{h,m}
│   │   │   │   ├── SFHybridViewConfig.{h,m}
│   │   │   │   ├── SalesforceWebViewCookieManager.swift
│   │   │   │   └── SalesforceHybridSDKManager.{h,m}
│   │   │   └── SalesforceHybridSDK.h
│   │   ├── SalesforceHybridSDKTests/  # Unit tests
│   │   └── SalesforceHybridSDK.xcodeproj
│   │
│   └── SalesforceFileLogger/         # File-based logging library
│       ├── SalesforceFileLogger/     # Library code
│       ├── SalesforceFileLoggerTests/ # Unit tests
│       └── SalesforceFileLogger.xcodeproj
│
├── hybrid/SampleApps/                # Sample applications
│   ├── AccountEditor/                # Account CRUD sample
│   └── MobileSyncExplorerHybrid/     # MobileSync demo app
│
├── external/                         # Git submodules
│   ├── SalesforceMobileSDK-iOS/      # iOS native SDK (submodule)
│   ├── shared/                       # SalesforceMobileSDK-Shared (submodule)
│   ├── cordova/                      # Apache Cordova iOS (submodule)
│   └── CocoaLumberjack/              # Logging library (submodule)
│
├── shared/                           # Shared resources
│   ├── hybrid/                       # Hybrid-specific code
│   │   ├── AppDelegate.m             # App delegate template
│   │   ├── InitialViewController.{h,m}
│   │   └── UIApplication+SalesforceHybridSDK.{h,m}
│   └── common/                       # Common utilities
│
├── SalesforceMobileSDK-Hybrid.xcworkspace
└── install.sh                        # Setup script
```

## Libraries

### SalesforceHybridSDK

**Purpose**: Bridge Cordova JavaScript plugins to iOS native SDK

**Key Components**:

| Component | Purpose |
|-----------|---------|
| **SFHybridViewController** | Main view controller for Cordova WebView, authentication flow, lifecycle management |
| **SFHybridViewConfig** | Configuration for hybrid views (local/remote, authentication settings) |
| **SalesforceWebViewCookieManager** | WKWebView cookie management for Salesforce sessions |
| **SalesforceHybridSDKManager** | Singleton SDK manager, hybrid-specific configuration |
| **SFHybridConnectionMonitor** | Network connectivity monitoring |
| **SFLocalhostSubstitutionCache** | Local file serving optimization |

**Cordova Plugins** (in `Classes/Plugins/`):

| Plugin | Native Class | Purpose |
|--------|--------------|---------|
| **OAuth** | `SalesforceOAuthPlugin` | Authentication, user management, logout |
| **SmartStore** | `SFSmartStorePlugin` | Encrypted local storage operations |
| **MobileSync** | `SFMobileSyncPlugin` | Data synchronization framework |
| **Network** | `SFNetworkPlugin` | REST API requests to Salesforce |
| **SDKInfo** | `SFSDKInfoPlugin` | SDK version and configuration info |
| **Account Manager** | `SFAccountManagerPlugin` | Multi-user account management |

### SalesforceFileLogger

**Purpose**: File-based logging for hybrid apps

**Features**:
- Log rotation and management
- Configurable log levels
- Log file export for debugging
- Integration with CocoaLumberjack

## Dependencies

### CocoaPods Dependencies

Declared in podspecs and pulled from iOS SDK:

```ruby
pod 'MobileSync'
pod 'SmartStore'
pod 'SalesforceSDKCore'
pod 'SalesforceAnalytics'
pod 'SalesforceSDKCommon'
pod 'Cordova'  # Apache Cordova for iOS
pod 'CocoaLumberjack'  # Logging framework
```

### Git Submodules

```bash
external/SalesforceMobileSDK-iOS    # iOS native SDK
external/shared                      # Shared JavaScript libraries
external/cordova                     # Apache Cordova iOS
external/CocoaLumberjack            # Logging library
```

## Build & Test Setup

### Prerequisites
- **macOS**: Required for iOS development
- **Xcode**: 15+ recommended
- **iOS**: Minimum deployment target 17.0
- **CocoaPods**: For dependency management

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/forcedotcom/SalesforceMobileSDK-iOS-Hybrid.git
cd SalesforceMobileSDK-iOS-Hybrid

# Run install script to pull submodules
./install.sh

# Open the workspace
open SalesforceMobileSDK-Hybrid.xcworkspace
```

**Important**: Always open `.xcworkspace`, not `.xcodeproj` files.

### Build Commands

```bash
# Build SalesforceHybridSDK
xcodebuild -workspace SalesforceMobileSDK-Hybrid.xcworkspace \
  -scheme SalesforceHybridSDK \
  -sdk iphonesimulator \
  build

# Run tests for SalesforceHybridSDK
xcodebuild test -workspace SalesforceMobileSDK-Hybrid.xcworkspace \
  -scheme SalesforceHybridSDK \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Build SalesforceFileLogger
xcodebuild -workspace SalesforceMobileSDK-Hybrid.xcworkspace \
  -scheme SalesforceFileLogger \
  -sdk iphonesimulator \
  build
```

### Sample Apps

Build and run sample apps from the workspace:

**AccountEditor**:
- Basic CRUD operations on Account records
- Demonstrates Cordova plugin usage

**MobileSyncExplorerHybrid**:
- Complete MobileSync demo
- Offline sync, conflict resolution
- SmartStore integration

## Code Standards

### General Rules (Both Platforms)
- **Public API changes require a deprecation cycle**. Deprecate in release N, remove no earlier than release N+2 (next major).
- **No hardcoded secrets, tokens, or PII in source**. Not even in test fixtures.
- **Never log PII, refresh tokens, or full request/response bodies**.
- **Compiler warnings are bugs**. Fix all warnings before submitting a PR.
- **Localization**: New user-facing strings must be added to `Localizable.strings`.

### iOS-Specific (Hybrid)
- **Objective-C for plugin bridges**: Cordova plugins use Objective-C for compatibility
- **Swift for new utilities**: Non-plugin code can use Swift (e.g., `SalesforceWebViewCookieManager.swift`)
- **Cordova plugin conventions**: Use `CDVPlugin`, `CDVInvokedUrlCommand`, proper callback handling
- **WKWebView required**: No UIWebView support (deprecated by Apple)
- **Thread safety**: Plugin methods may be called from any thread
- **Memory management**: Follow ARC conventions, careful with WKWebView retain cycles

### Naming Conventions
- **Classes/Structs/Protocols**: `PascalCase` (prefix `SF` for Objective-C public types)
- **Functions/Methods/Properties**: `camelCase`
- **Cordova plugins**: Prefix with `Salesforce` or `SF`

## Testing Standards

### Unit Tests
- **Framework**: XCTest
- **Location**: `libs/SalesforceHybridSDK/SalesforceHybridSDKTests/`
- **Coverage target**: 80% line coverage for new code
- **Naming**: `test_given[Precondition]_when[Action]_then[Expected]`

### What to Test

**SalesforceHybridSDK**:
- Cordova plugin bridge methods (all plugins)
- View controller lifecycle and authentication flow
- Cookie management and session handling
- Local/remote hybrid view configurations
- Network connectivity monitoring
- Error handling and edge cases

**SalesforceFileLogger**:
- Log rotation and file management
- Log level filtering
- File export functionality
- Integration with CocoaLumberjack

### Integration Tests

Sample apps serve as integration tests:
- Build and run `AccountEditor` to verify basic plugin functionality
- Build and run `MobileSyncExplorerHybrid` for complete sync workflows

## Cross-Platform Change Workflow

When making changes that affect hybrid functionality:

1. **Modify iOS bridge** in this repo (`libs/SalesforceHybridSDK/`)
2. **Modify Android bridge** in Android repo (`libs/SalesforceHybrid/`)
3. **Modify JavaScript** in Shared repo (if plugin interface changes)
4. **Update CordovaPlugin** repo via `tools/update.sh`
5. **Test hybrid templates** in Templates repo
6. **Run iOS unit tests** for SalesforceHybridSDK
7. **Run Android unit tests** in Android repo for SalesforceHybrid
8. **Verify sample apps** work on both platforms

**Important**: A complete hybrid feature requires changes in multiple repos:
- This repo (iOS bridge)
- Android repo (Android bridge)
- Shared repo (JavaScript, if plugin interface changes)
- CordovaPlugin repo (update script to copy changes)
- Templates repo (if template updates needed)

## Code Review Checklist

When reviewing PRs:

- [ ] **Both platforms updated**: iOS and Android bridge both implement the change
- [ ] **Backward compatibility**: No breaking changes without deprecation cycle
- [ ] **Shared repo updated**: JavaScript interface matches native implementation
- [ ] **Tests included**: Unit tests for new functionality
- [ ] **iOS tests pass**: Run SalesforceHybridSDK test suite
- [ ] **Android tests pass**: Verify in Android repo
- [ ] **Sample apps work**: AccountEditor and MobileSyncExplorerHybrid still function
- [ ] **No console warnings**: No Xcode warnings or deprecation notices
- [ ] **Documentation**: Public APIs have header doc comments
- [ ] **Templates work**: Test with hybrid templates if API changed
- [ ] **Submodules**: Appropriate submodule versions referenced

## Agent Behavior Guidelines

### Do
- Always run unit tests before committing
- Test sample apps after making changes
- Check both iOS and Android implementations for consistency
- Update JavaScript in Shared repo when plugin interfaces change
- Reference iOS SDK CLAUDE.md for native SDK patterns
- Consider WKWebView threading and memory management

### Don't
- Don't merge without human approval (public SDK)
- Don't modify submodule references without explicit request
- Don't change Cordova plugin interfaces without matching Android changes
- Don't add new dependencies without flagging for review
- Don't suppress warnings or test failures
- Don't modify `install.sh` without explicit request

### Escalation — Stop and Flag for Human Review
- Any change to Cordova plugin interfaces
- OAuth flow, token storage, or credential handling changes
- WKWebView configuration or cookie management changes
- New public APIs or API signature modifications
- Build system changes (Xcode project, CocoaPods, podspecs)
- Dependency version bumps (Cordova, iOS SDK, CocoaLumberjack)
- Submodule reference updates
- Removal of any previously deprecated API

## Key Domain Concepts

Understanding these concepts is essential:

- **Cordova Plugin**: Native iOS class (subclass of `CDVPlugin`) that exposes methods to JavaScript
- **CDVInvokedUrlCommand**: Cordova's wrapper for plugin method calls from JavaScript, includes callback IDs
- **WKWebView**: Modern WebKit view (required, UIWebView is deprecated)
- **Hybrid View Config**: Configuration specifying local vs remote app, authentication behavior
- **Cookie Bridge**: Mechanism to share Salesforce session cookies between native and WKWebView
- **Bootstrap**: Initial authentication and WebView setup before loading app content
- **External Client App or Connected App (legacy)**: Salesforce OAuth configuration (defined in app, not in SDK)
- **Localhost Substitution**: Performance optimization for loading local files

## Release & Distribution

### CocoaPods Distribution
- **Pod name**: `SalesforceHybridSDK`
- **Registry**: SalesforceMobileSDK-iOS-Specs (private podspec repo)
- **Release process**: Coordinated with iOS SDK releases

### Submodule in CordovaPlugin
The CordovaPlugin repo references this repo and copies files during release:
```bash
cd SalesforceMobileSDK-CordovaPlugin
./tools/update.sh -b dev -o ios
```

This copies:
- iOS bridge code from `shared/hybrid/` → `src/ios/classes/`
- Resources from iOS SDK → `src/ios/resources/`

### Template Integration
Hybrid templates depend on CordovaPlugin, which references this repo:
- `HybridLocalTemplate` - Local HTML/JS app
- `HybridRemoteTemplate` - Remote Visualforce/Community app

## Related Documentation

- **Mobile SDK Development Guide**: https://developer.salesforce.com/docs/platform/mobile-sdk/guide
- **iOS SDK**: See `SalesforceMobileSDK-iOS/CLAUDE.md` for native SDK details
- **Android Hybrid**: See `SalesforceMobileSDK-Android/CLAUDE.md` (libs/SalesforceHybrid section)
- **Shared JavaScript**: See `SalesforceMobileSDK-Shared/CLAUDE.md`
- **CordovaPlugin**: See `SalesforceMobileSDK-CordovaPlugin/CLAUDE.md`
- **Cordova iOS**: https://cordova.apache.org/docs/en/latest/guide/platforms/ios/
- **iOS Library References**: https://forcedotcom.github.io/SalesforceMobileSDK-iOS
