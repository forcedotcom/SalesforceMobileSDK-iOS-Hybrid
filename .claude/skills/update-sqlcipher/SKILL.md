---
skill: sqlcipher-update
description: Update SQLCipher dependency in Salesforce Mobile SDK for iOS Hybrid
globs:
  - "*.podspec"
  - "external/SalesforceMobileSDK-iOS"
tags:
  - dependency-update
  - sqlcipher
  - encryption
  - smartstore
  - hybrid
---

# Update SQLCipher Skill (iOS Hybrid)

This skill automates the process of updating the SQLCipher library version in the SalesforceMobileSDK-iOS-Hybrid project.

## When to Use
Use this skill when you need to:
- Update SQLCipher to a newer version for security patches or new features
- Sync with SQLCipher updates in the iOS native SDK
- Track changes in SQLCipher's OpenSSL provider version

## Background
The iOS Hybrid SDK depends on the iOS native SDK (included as a git submodule) which contains SmartStore with SQLCipher support. The hybrid SDK doesn't directly depend on SQLCipher but inherits it through the MobileSync dependency in its podspec.

## Parameters
- `NEW_VERSION`: The new SQLCipher version (e.g., "4.15.0", "4.16.0")
- `OLD_VERSION`: The current SQLCipher version (check iOS submodule)
- `NEW_PROVIDER_VERSION`: The cipher provider version bundled with the new SQLCipher (check SQLCipher release notes)

## Prerequisite
- iOS submodule must have the SQLCipher update completed first
- The iOS submodule branch (e.g., `sqlcipher-4.16`) should exist and be ready

## Process

### 1. Research the New Version

Before starting, check the SQLCipher release notes:
- Visit: https://github.com/sqlcipher/sqlcipher/releases
- Review changes, breaking changes, and new features
- Note the provider version included (important for tests)
- Check the iOS native SDK repository for the SQLCipher update PR/branch

**Key things to look for:**
- Changes already handled in the iOS native SDK
- Any hybrid-specific implications
- Security fixes or enhancements
- Changes to encryption algorithms or key derivation

### 2. Update iOS Submodule Reference

The iOS Hybrid SDK includes the iOS native SDK as a git submodule at `external/SalesforceMobileSDK-iOS`.

**Check current submodule status:**
```bash
cd /path/to/SalesforceMobileSDK-iOS-Hybrid
git submodule status
```

**Update the submodule to the new SQLCipher branch:**
```bash
cd external/SalesforceMobileSDK-iOS
git fetch origin
git checkout origin/sqlcipher-4.16  # or appropriate branch
cd ../..
git add external/SalesforceMobileSDK-iOS
```

The submodule will now point to the iOS SDK commit with the SQLCipher update.

### 3. Update Swift Package Manager Dependencies

**CRITICAL:** The workspace and sample apps use Swift Package Manager for SQLCipher dependencies. These must be updated to match the iOS submodule version.

#### 3.1. Update Workspace Package.resolved

Update `SalesforceMobileSDK-Hybrid.xcworkspace/xcshareddata/swiftpm/Package.resolved`:

```json
{
  "identity" : "sqlcipher.swift",
  "kind" : "remoteSourceControl",
  "location" : "https://github.com/sqlcipher/SQLCipher.swift",
  "state" : {
    "revision" : "<COMMIT_HASH>",  // Get from SQLCipher tag
    "version" : "4.16.0"  // Update to new version
  }
}
```

**To find the correct commit hash:**
```bash
git clone --depth=1 --branch 4.16.0 https://github.com/sqlcipher/SQLCipher.swift /tmp/sqlcipher-check
cd /tmp/sqlcipher-check
git log -1 --format="%H"
```

#### 3.2. Update Sample App Project Files

Both sample apps have direct SQLCipher package references that must be updated:

**MobileSyncExplorerHybrid:**
Edit `hybrid/SampleApps/MobileSyncExplorerHybrid/MobileSyncExplorerHybrid.xcodeproj/project.pbxproj`:

Find the section `XCRemoteSwiftPackageReference "SQLCipher"` and update:
```
requirement = {
    kind = exactVersion;
    version = 4.16.0;  // Update from 4.15.0
};
```

**AccountEditor:**
Edit `hybrid/SampleApps/AccountEditor/AccountEditor.xcodeproj/project.pbxproj`:

Find the section `XCRemoteSwiftPackageReference "SQLCipher"` and update:
```
requirement = {
    kind = exactVersion;
    version = 4.16.0;  // Update from 4.15.0
};
```

**Why this is needed:** The sample apps declare exact SQLCipher versions in their project files. If these don't match the iOS submodule's version, Xcode's package resolution will fail with:
```
Could not resolve package dependencies:
  Failed to resolve dependencies Dependencies could not be resolved because root depends on 'sqlcipher.swift' 4.16.0 and root depends on 'sqlcipher.swift' 4.15.0.
```

### 4. Verify Podspec Dependencies

Check `SalesforceHybridSDK.podspec`:

```ruby
s.subspec 'SalesforceHybridSDK' do |sdkhybrid|
    sdkhybrid.dependency 'MobileSync', "~>#{s.version}"
    sdkhybrid.dependency 'Cordova', '7.1.1'
    # ... other dependencies
end
```

The hybrid SDK depends on `MobileSync` from the iOS SDK, which transitively depends on SmartStore and SQLCipher. No direct SQLCipher dependency should be needed here.

**Important:** The iOS SDK's podspec (SmartStore.podspec) should already have the updated SQLCipher dependency. The hybrid SDK inherits it.

### 5. Build the Hybrid SDK

Build the SalesforceHybridSDK library to catch compilation issues:

```bash
xcodebuild -workspace SalesforceMobileSDK-Hybrid.xcworkspace \
  -scheme SalesforceHybridSDK \
  -sdk iphonesimulator \
  build
```

Address any compilation errors related to:
- Changes in the iOS SDK that affect hybrid code
- Header import changes
- API changes in MobileSync or SmartStore
- Cordova plugin compatibility

### 6. Run Hybrid SDK Tests

**CRITICAL**: Full SalesforceHybridSDK test suite must pass before proceeding.

```bash
xcodebuild test -workspace SalesforceMobileSDK-Hybrid.xcworkspace \
  -scheme SalesforceHybridSDK \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Key tests to verify:**
- Hybrid authentication and session management
- Cordova plugin functionality (OAuth, SmartStore, MobileSync, Network)
- SmartStore operations through hybrid plugins
- MobileSync operations through hybrid plugins
- WebView cookie management with encrypted storage

**Common test failures:**
- Cordova plugin bridge issues if iOS SDK API changed
- SmartStore plugin errors if encryption behavior changed
- Session management issues if OAuth/identity flow changed

If tests fail:
- Check if the iOS SDK introduced API changes affecting hybrid plugins
- Review Cordova plugin implementations in `libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/Plugins/`
- Compare behavior with the iOS SDK's SmartStore tests

### 7. Verify Sample Apps

Test the hybrid sample applications:

```bash
# Build AccountEditor sample
xcodebuild -workspace SalesforceMobileSDK-Hybrid.xcworkspace \
  -scheme AccountEditor \
  -sdk iphonesimulator \
  build

# Build MobileSyncExplorerHybrid sample
xcodebuild -workspace SalesforceMobileSDK-Hybrid.xcworkspace \
  -scheme MobileSyncExplorerHybrid \
  -sdk iphonesimulator \
  build
```

Run the sample apps on a simulator to ensure:
- App launches successfully
- Authentication works
- SmartStore operations function correctly
- MobileSync operations function correctly

### 8. Check Cross-Platform Consistency

Since this is a hybrid SDK:
- Verify the Android hybrid SDK has the corresponding SQLCipher update
- Check the Shared repo for any JavaScript changes needed
- Ensure CordovaPlugin repo is aware of the update (will need `tools/update.sh` run)

### 9. Create Pull Request

When creating the PR:
- **Branch name:** `sqlcipher-4.16` (or appropriate version)
- **Title:** "Update SQLCipher to {NEW_VERSION}" or "Update iOS submodule for SQLCipher {NEW_VERSION}"
- **Description:** Include:
  - SQLCipher version being updated to
  - iOS submodule commit reference
  - Link to iOS SDK PR with SQLCipher update
  - Link to SQLCipher release notes
  - Test results summary
  - Any hybrid-specific changes or notes
  - Cross-platform status (Android update status)

## File Checklist

- [ ] `external/SalesforceMobileSDK-iOS` - Update submodule reference
- [ ] `SalesforceMobileSDK-Hybrid.xcworkspace/xcshareddata/swiftpm/Package.resolved` - Update SQLCipher version and commit hash
- [ ] `hybrid/SampleApps/MobileSyncExplorerHybrid/MobileSyncExplorerHybrid.xcodeproj/project.pbxproj` - Update SQLCipher package version
- [ ] `hybrid/SampleApps/AccountEditor/AccountEditor.xcodeproj/project.pbxproj` - Update SQLCipher package version
- [ ] `SalesforceHybridSDK.podspec` - Verify dependencies (usually no change needed)
- [ ] Run full SalesforceHybridSDK test suite
- [ ] Build and test AccountEditor sample app
- [ ] Build and test MobileSyncExplorerHybrid sample app
- [ ] Verify on multiple iOS versions (min deployment target to latest)
- [ ] Check Android hybrid SDK has corresponding update
- [ ] Note CordovaPlugin repo will need update

## Key Files Reference

**Submodules:**
- `external/SalesforceMobileSDK-iOS` - iOS native SDK submodule (contains SmartStore with SQLCipher)
- `external/shared` - Shared JavaScript libraries
- `external/cordova` - Apache Cordova iOS

**Build Configuration:**
- `SalesforceHybridSDK.podspec` - Hybrid SDK pod specification
- `SalesforceMobileSDK-Hybrid.xcworkspace` - Xcode workspace

**Hybrid Plugin Source Files:**
- `libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/Plugins/SFSmartStorePlugin/` - SmartStore Cordova plugin
- `libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/Plugins/SFMobileSyncPlugin/` - MobileSync Cordova plugin

**Test Files:**
- `libs/SalesforceHybridSDK/SalesforceHybridSDKTests/` - Hybrid SDK test suite

**Sample Apps:**
- `hybrid/SampleApps/AccountEditor/` - Basic CRUD sample
- `hybrid/SampleApps/MobileSyncExplorerHybrid/` - Complete sync demo

## Troubleshooting

### Package Resolution Failures

**Error:**
```
xcodebuild: error: Could not resolve package dependencies:
  Failed to resolve dependencies Dependencies could not be resolved because root depends on 'sqlcipher.swift' 4.16.0 and root depends on 'sqlcipher.swift' 4.15.0.
```

**Cause:** Version mismatch between:
- iOS submodule's SQLCipher dependency (in SmartStore.podspec)
- Workspace Package.resolved
- Sample app project files

**Solution:**
1. Check iOS submodule version: `grep -A 5 "SQLCipher" external/SalesforceMobileSDK-iOS/SmartStore.podspec`
2. Update workspace Package.resolved to match
3. Update both sample app project.pbxproj files to match
4. Clean build folder: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`

### Wrong Commit Hash in Package.resolved

**Error:**
```
Couldn't check out revision 'xxxxx':
    fatal: unable to read tree (xxxxx)
```

**Cause:** Incorrect commit hash in Package.resolved

**Solution:**
```bash
git clone --depth=1 --branch 4.16.0 https://github.com/sqlcipher/SQLCipher.swift /tmp/sqlcipher-check
cd /tmp/sqlcipher-check
git log -1 --format="%H"
# Use this hash in Package.resolved
```

### Sample Apps Won't Build After Update

**Cause:** Sample app project files still reference old SQLCipher version

**Solution:**
Search for old version in project files:
```bash
grep -r "4.15.0" hybrid/SampleApps/*/*/project.pbxproj
```
Update all occurrences to new version.

## Notes

- The iOS Hybrid SDK doesn't directly manage SQLCipher dependencies
- SQLCipher updates flow through the iOS SDK submodule
- Always update the iOS SDK first, then update the submodule reference
- The hybrid SDK's dependency on MobileSync brings in SmartStore and SQLCipher transitively
- **Swift Package Manager is used by the workspace and sample apps** - these must be updated separately from podspecs
- Hybrid plugins (SFSmartStorePlugin, SFMobileSyncPlugin) bridge JavaScript to the native iOS SDK
- Test with encrypted databases from previous versions to ensure migration works
- After updating, the CordovaPlugin repo will need to run `tools/update.sh` to sync changes

## Cross-Repository Impact

This update affects:
1. **iOS-Hybrid** (this repo) - Submodule reference update
2. **iOS** - Direct SQLCipher dependency (should be updated first)
3. **Shared** - JavaScript libraries (usually no change for SQLCipher updates)
4. **CordovaPlugin** - Needs `tools/update.sh` run after iOS-Hybrid update
5. **Templates** - Hybrid templates reference CordovaPlugin (will pick up changes automatically)
6. **Android** - Should have corresponding SQLCipher update for consistency

## Resources

- SQLCipher: https://www.zetetic.net/sqlcipher/
- SQLCipher Releases: https://github.com/sqlcipher/sqlcipher/releases
- iOS SDK CLAUDE.md: See `external/SalesforceMobileSDK-iOS/CLAUDE.md` for iOS-specific details
- Cordova iOS: https://cordova.apache.org/docs/en/latest/guide/platforms/ios/
- iOS Hybrid SDK docs: See CLAUDE.md in this repo
