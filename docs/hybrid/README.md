# iOS Hybrid SDK — Contributor Guide

This repository provides the **iOS native bridge** for Salesforce Mobile SDK hybrid (Cordova) apps. It delivers the `SalesforceHybridSDK` CocoaPods pod and contains the Objective-C bootstrap files that are copied into the CordovaPlugin distribution.

**Minimum iOS deployment target:** 18.0

---

## SalesforceHybridSDK Pod

The primary deliverable is the `SalesforceHybridSDK` pod, declared in `SalesforceHybridSDK.podspec` at the repo root.

| Attribute | Value |
|-----------|-------|
| Pod name | `SalesforceHybridSDK` |
| Current version | 14.1.0 |
| Key dependency | `MobileSync ~> 14.1.0` (pulls the full iOS SDK chain) |
| Cordova dependency | `Cordova 8.2.0` |
| Source files | `libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/**/*.{h,m,swift}` |

In **development builds**, CordovaPlugin's `plugin.xml` selects this pod from its configured Git source. The matched Cordova upgrade pins the reviewed Hybrid commit; other development sources retain their branch policy. In **GA releases**, the pod is selected by version tag (for example, `v14.0.0`).

---

## Plugin Classes

Located under `libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/Plugins/`:

| Plugin | Directory | Header | Purpose |
|--------|-----------|--------|---------|
| `SalesforceOAuthPlugin` | `SFOAuthPlugin/` | `SalesforceOAuthPlugin.h` | OAuth authentication and user management |
| `SFNetworkPlugin` | `SFNetworkPlugin/` | `SFNetworkPlugin.h` | REST API requests to Salesforce |
| `SFSDKInfoPlugin` | `SDKInfo/` | `SFSDKInfoPlugin.h` | SDK version and configuration info |
| `SFSmartStorePlugin` | `SFSmartStore/` | `SFSmartStorePlugin.h` | Encrypted local storage (SmartStore) |
| `SFMobileSyncPlugin` | `SFMobileSyncPlugin/` | `SFMobileSyncPlugin.h` | Data synchronization framework |
| `SFAccountManagerPlugin` | `SFAccountManagerPlugin/` | `SFAccountManagerPlugin.h` | Multi-user account management |
| `SFForcePlugin` | `SFForcePlugin/` | `SFForcePlugin.h` | Base class for Salesforce Cordova plugins |
| `CDVPlugin+SFAdditions` | `SFAdditions/` | `CDVPlugin+SFAdditions.h` | Category adding Salesforce helpers to CDVPlugin |

Each plugin is an Objective-C subclass of `CDVPlugin` (or `SFForcePlugin`) and exposes methods callable from JavaScript via the Cordova bridge.

---

## `shared/hybrid/` — Bootstrap Files Copied to CordovaPlugin

The `shared/hybrid/` directory contains Objective-C files that `tools/update.sh` in the CordovaPlugin repo copies to `src/ios/classes/`:

| File | Role |
|------|------|
| `AppDelegate.swift` | Application entry point — bootstraps the Salesforce hybrid runtime (SDK init, OAuth, URL cache, view controller setup). Uses `@main @_objcImplementation extension AppDelegate` pattern required by cordova-ios 8.x. |
| `InitialViewController.h` / `.m` | Root view controller displayed before the Cordova WKWebView loads |
| `UIApplication+SalesforceHybridSDK.h` / `.m` | UIApplication category that tracks last-event timing for passcode inactivity |

The directory also contains `config.xml` and `cordova_plugins.js`, but only the Swift/ObjC source files are copied to the CordovaPlugin.

### Why `AppDelegate.swift` lives here and how it reaches the generated app

When `cordova platform add ios` runs, Cordova generates its own `AppDelegate.swift`. The CordovaPlugin's `postinstall-ios.js` hook:
1. Copies our `AppDelegate.swift` from the plugin into `platforms/ios/App/Plugins/com.salesforce/`
2. Patches `project.pbxproj` to redirect the app target's `AppDelegate.swift` reference to `Plugins/com.salesforce/AppDelegate.swift`
3. Adds `#import "InitialViewController.h"` to the Bridging-Header so the ObjC class is accessible from Swift

Without this, Cordova's bare `AppDelegate.swift` would be used and the Salesforce SDK would never initialize.

**Note:** `AppDelegate.swift` is intentionally **not** declared as a `<source-file>` in `plugin.xml`. In cordova-ios 8.x, `<source-file>` entries go into the `CordovaPlugins` SPM target, which cannot link CocoaPods frameworks like `SalesforceHybridSDK`. The copy + redirect approach is the correct workaround.

---

## `external/shared/` — Shared JavaScript Submodule

SalesforceMobileSDK-Shared is included as a git submodule at `external/shared/`. The hybrid sample apps reference JavaScript libraries (force.js, smartstore.js, mobilesync.js) from this submodule.

Other submodules:

| Path | Repository |
|------|------------|
| `external/SalesforceMobileSDK-iOS` | iOS native SDK |

Cordova and CocoaLumberjack are Swift Package Manager dependencies of the Xcode
projects, rather than Git submodules.

---

## Sample Apps

Located under `hybrid/SampleApps/`:

- **AccountEditor** — Basic CRUD operations on Account records using Cordova plugins and `force.js`
- **MobileSyncExplorerHybrid** — Full offline sync demo using SmartStore and MobileSync

### How sample apps are structured

The sample apps are standard Xcode projects that wire together the following sources via relative paths in `project.pbxproj`:

| Source | What it provides |
|--------|-----------------|
| `external/shared/samples/<appname>/` | App HTML, CSS, JS, `bootconfig.json`, sync configs (from Shared submodule) |
| `external/shared/gen/plugins_with_define/` | Cordova plugin JS files copied to `www/plugins/com.salesforce/` (from Shared submodule) |
| `shared/hybrid/` | `AppDelegate.swift`, `InitialViewController.{h,m}`, `UIApplication+SalesforceHybridSDK.{h,m}`, `config.xml`, `cordova_plugins.js`, and bundled `www/cordova.js` |
| Cordova Swift package | `CDVAppDelegate` and CordovaLib native implementation |
| `external/SalesforceMobileSDK-iOS/` | SDK library `.xcodeproj` files and shared resources (from iOS SDK submodule) |

None of the app-specific source files live in the `hybrid/SampleApps/` directory itself — the Xcode projects are essentially just wiring. All content is pulled from submodules and `shared/hybrid/`.

### Building the sample apps

Prerequisites: run `./install.sh` from the repo root to populate all external submodules.

```bash
# Open the workspace (not individual .xcodeproj files)
open SalesforceMobileSDK-Hybrid.xcworkspace
```

Select the `AccountEditor` or `MobileSyncExplorerHybrid` scheme and build. Before running:
- Fill in your Connected App credentials in `external/shared/samples/<appname>/bootconfig.json`

### Cordova version dependency

The sample apps use SalesforceHybridSDK's Cordova Swift package dependency, pinned to the `rel/8.2.0` revision. Their bundled JavaScript comes from `shared/hybrid/www/cordova.js`, copied from the same cordova-ios npm release.

For a Cordova upgrade, update the Xcode package revision, the exact Cordova requirement in `SalesforceHybridSDK.podspec`, and the bundled JavaScript together. The CordovaPlugin iOS engine requirement and Cordova pod tag, plus Package's iOS platform version, must agree with that version. Validate compatible Hybrid and plugin snapshots together: plugin installation runs CocoaPods before Package applies SDK dependency overrides, so the first installation must already select a compatible Hybrid source. Coordinate publication of the companion snapshots before exposing the new CLI platform version to consumers.

---

## Version Management

`setversion.sh` updates the SDK version in both podspecs:

```bash
./setversion.sh -v 14.0.0
```

This updates `s.version` in `SalesforceHybridSDK.podspec` and `SalesforceFileLogger.podspec`. This script has no `-d` flag. Development/GA source selection is controlled by CordovaPlugin's `plugin.xml`: development builds can select a branch or a matched commit, while GA builds use the release tag.

---

## Running Unit Tests

For Cordova dependency changes, use `docs/hybrid/cordova-upgrade-validation.md` in [SalesforceMobileSDK-Package](https://github.com/forcedotcom/SalesforceMobileSDK-Package) at the revision matching the SDK sources under test. Record authenticated, Release and device results separately.

Open the workspace and run the `SalesforceHybridSDK` scheme tests:

```bash
# Setup (first time)
./install.sh

# Run tests
xcodebuild test \
  -workspace SalesforceMobileSDK-Hybrid.xcworkspace \
  -scheme SalesforceHybridSDK \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Always open `SalesforceMobileSDK-Hybrid.xcworkspace` (not individual `.xcodeproj` files) to ensure CocoaPods dependencies resolve correctly.

Most tests require a `test_credentials.json` file at `shared/test/test_credentials.json`. Without it, only tests that do not make authenticated Salesforce API calls will pass. Copy the sample and fill in your org details:

```bash
cp shared/test/test_credentials.json.sample shared/test/test_credentials.json
# then edit with your Connected App credentials and org details
```

The file must contain:

```json
{
  "test_client_id":    "<Connected App consumer key>",
  "test_login_domain": "<login URL, e.g. test.salesforce.com>",
  "test_redirect_uri": "<Connected App callback URL>",
  "refresh_token":     "<valid refresh token>",
  "instance_url":      "<org instance URL>",
  "identity_url":      "<identity URL>"
}
```

`test_credentials.json` is gitignored — never commit real credentials.

### Custom WebView UI delegates

A hybrid controller that implements `WKUIDelegate` receives callbacks through a weak forwarding delegate. Cordova owns the forwarding delegate, which preserves optional-method detection and forwards calls to the controller without retaining it. Consequently, `webView.UIDelegate` is a forwarding object rather than the controller itself; use callback behavior instead of delegate pointer identity. Separate application-supplied delegate objects remain unchanged.
