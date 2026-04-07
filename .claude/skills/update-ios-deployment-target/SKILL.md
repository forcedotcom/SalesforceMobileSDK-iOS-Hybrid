# Update iOS Minimum Deployment Target

This skill updates the minimum iOS deployment target across the Salesforce Mobile SDK for iOS Hybrid repository.

## When to Use
- When bumping the minimum supported iOS version for a new SDK release
- Typically done once per major release cycle
- **IMPORTANT**: Must be coordinated with iOS SDK deployment target updates (iOS-Hybrid depends on iOS SDK via submodule)

## What This Skill Does

Updates the iOS deployment target in all necessary locations:

1. **CocoaPods Specifications** - Updates platform version in both podspec files (SalesforceHybridSDK, SalesforceFileLogger)
2. **Project Files** - Updates all .pbxproj files for libraries and sample apps
3. **Documentation** - Updates README.md with new minimum version
4. **GitHub Actions Workflows** - Updates CI workflow matrices and runtime installation steps
5. **Code Cleanup** - Identifies and removes obsolete version checks in source code
6. **Comment Updates** - Updates version references in code comments

**Note**: iOS-Hybrid inherits deployment target configuration from the iOS SDK submodule at `external/SalesforceMobileSDK-iOS/configuration/`. The iOS SDK must be updated first.

## Usage

When invoked, ask the user for:
- **Current minimum iOS version** (e.g., "16.0")
- **New minimum iOS version** (e.g., "17.0")
- **iOS SDK submodule status** - Verify that the iOS SDK submodule has already been updated with the new deployment target

## Step-by-Step Process

### 0. Prerequisites - Update iOS SDK Submodule First
**CRITICAL**: The iOS SDK must be updated with the new deployment target BEFORE updating iOS-Hybrid.

iOS-Hybrid inherits deployment target configuration from `external/SalesforceMobileSDK-iOS/configuration/`. 

Verify the iOS SDK submodule is updated:
```bash
cd external/SalesforceMobileSDK-iOS
git log --oneline -5  # Check recent commits for deployment target update
```

If not updated, coordinate with iOS SDK update first.

### 1. Update CocoaPods Specifications
Update `s.platform = :ios, "X.0"` in:
- SalesforceHybridSDK.podspec
- SalesforceFileLogger.podspec

### 2. Update Documentation
In `README.md` and `CLAUDE.md`:
- Update minimum iOS version requirement

### 3. Update Xcode Project Files
Find all .pbxproj files and update `IPHONEOS_DEPLOYMENT_TARGET`:
- libs/SalesforceHybridSDK/SalesforceHybridSDK.xcodeproj/project.pbxproj
- libs/SalesforceFileLogger/SalesforceFileLogger.xcodeproj/project.pbxproj
- hybrid/SampleApps/AccountEditor/AccountEditor.xcodeproj/project.pbxproj
- hybrid/SampleApps/MobileSyncExplorerHybrid/MobileSyncExplorerHybrid.xcodeproj/project.pbxproj

### 4. Update GitHub Actions Workflows
Remove the old minimum iOS version from CI workflows and clean up runtime installation steps:

In `.github/workflows/nightly.yaml`:
- Remove old iOS version from test matrix (e.g., `ios: [^26, ^18, ^17]` → `ios: [^26, ^18]`)
- Remove old iOS version from build matrix
- Remove corresponding Xcode version mapping from matrix.include


### 5. Code Cleanup - Remove Obsolete Version Checks
Search for and review code with version-specific conditional compilation in hybrid-specific code:
- `#if __IPHONE_OS_VERSION_MAX_ALLOWED >= [OLD_VERSION]`
- `@available(iOS X.Y, *)`
- `if #available(iOS X.Y, *)`

For each occurrence where the check is for a version now below the new minimum:
- Remove the conditional wrapper
- Keep only the modern code path
- Remove else/fallback branches for old iOS versions

Example patterns to search for:
```bash
# Find preprocessor conditionals in hybrid libraries
grep -r "#if __IPHONE_OS_VERSION_MAX_ALLOWED" libs/SalesforceHybridSDK/ libs/SalesforceFileLogger/

# Find availability checks in Swift
grep -r "@available(iOS" libs/SalesforceHybridSDK/ libs/SalesforceFileLogger/

# Find availability checks in Objective-C
grep -r "respondsToSelector" libs/SalesforceHybridSDK/ libs/SalesforceFileLogger/
```

**Note**: The iOS SDK libraries (in `external/SalesforceMobileSDK-iOS/`) are handled separately in the iOS repo.

### 5. Update Version References in Comments
Search for and update comments that reference the old minimum version in hybrid-specific code:
```bash
grep -r "iOS [OLD_VERSION]" libs/SalesforceHybridSDK/ libs/SalesforceFileLogger/ hybrid/ shared/ --include="*.swift" --include="*.m" --include="*.h"
```

## Post-Update Tasks

1. **Build Verification**: Build all library schemes to verify no compilation errors
2. **Sample App Check**: Build and run sample apps (AccountEditor, MobileSyncExplorerHybrid)
3. **iOS SDK Submodule**: Update submodule reference if iOS SDK has a new commit


## Important Notes

- **STOP and FLAG for human review**: This is a significant change that affects all SDK consumers
- **Release timing**: Only bump deployment target at major releases, never patches
- **Breaking change**: Document this in migration guide and release notes
- **iOS SDK dependency**: iOS-Hybrid MUST coordinate with iOS SDK - update iOS SDK submodule first


## Example Command Flow

```bash
# 0. FIRST: Verify iOS SDK submodule is updated
cd external/SalesforceMobileSDK-iOS
git log --oneline -5  # Check for deployment target update
cd ../..

# 1. Create a feature branch
git checkout -b bump-ios-18

# 2. Use this skill to make all updates
# (skill automates file edits)

# 3. Search for version-specific code in hybrid libraries
grep -r "@available(iOS 17" libs/SalesforceHybridSDK/ libs/SalesforceFileLogger/ --include="*.swift"
grep -r "#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 170000" libs/SalesforceHybridSDK/ libs/SalesforceFileLogger/

# 4. Build all libraries
xcodebuild -workspace SalesforceMobileSDK-Hybrid.xcworkspace -scheme SalesforceHybridSDK -sdk iphonesimulator
xcodebuild -workspace SalesforceMobileSDK-Hybrid.xcworkspace -scheme SalesforceFileLogger -sdk iphonesimulator

# 5. Build sample apps
xcodebuild -workspace SalesforceMobileSDK-Hybrid.xcworkspace -scheme AccountEditor -sdk iphonesimulator
xcodebuild -workspace SalesforceMobileSDK-Hybrid.xcworkspace -scheme MobileSyncExplorerHybrid -sdk iphonesimulator

```

## Historical References
- Check PR history in forcedotcom/SalesforceMobileSDK-iOS-Hybrid for previous deployment target updates
- iOS SDK historical references:
  - PR #260: iOS 16 → iOS 17 bump
  - PR #233: iOS 15 → iOS 16 bump

## Checklist

Before marking complete:
- [ ] **iOS SDK submodule verified updated with new deployment target**
- [ ] Both podspec files updated (SalesforceHybridSDK.podspec, SalesforceFileLogger.podspec)
- [ ] README.md updated
- [ ] All .pbxproj files updated (2 libraries + 2 sample apps)
- [ ] Obsolete version checks removed from hybrid-specific code
- [ ] Version references in comments updated
- [ ] SalesforceHybridSDK library builds successfully
- [ ] SalesforceFileLogger library builds successfully
- [ ] AccountEditor sample app builds
- [ ] MobileSyncExplorerHybrid sample app builds
