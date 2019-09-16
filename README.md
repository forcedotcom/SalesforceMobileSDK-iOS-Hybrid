[![CircleCI](https://circleci.com/gh/forcedotcom/SalesforceMobileSDK-iOS-Hybrid/tree/dev.svg?style=svg)](https://circleci.com/gh/forcedotcom/SalesforceMobileSDK-iOS-Hybrid/tree/dev)
[![codecov](https://codecov.io/gh/forcedotcom/SalesforceMobileSDK-iOS-Hybrid/branch/dev/graph/badge.svg)](https://codecov.io/gh/forcedotcom/SalesforceMobileSDK-iOS-Hybrid/branch/dev)

# Hybrid library / sample apps and tests for Salesforce.com Mobile SDK on iOS

You have arrived at the source repository for the Hybrid library of the Salesforce Mobile SDK on iOS.  Welcome!

- If you'd like to work with the source code of the SDK itself, you've come to the right place!  You can browse sample app source code and debug down through the layers to get a feel for how everything works under the covers.  Read on for instructions on how to get started with the SDK in your development environment.
- If you're just eager to start developing your own new application, the quickest way is to use our npm binary distribution package, called [forcehybrid](https://npmjs.org/package/forcehybrid), which is hosted on [npmjs.org](https://npmjs.org/).  Getting started is as simple as installing the npm package and launching your template app.  You'll find more details on the forcehybrid package page.

Installation (do this first - really)
==
Working with this repository requires working with git.  Any workflow that leaves you with a functioning git clone of this repository should set you up for success.  Downloading the ZIP file from GitHub, on the other hand, is likely to put you at a dead end.

## Setting up the repo
First, clone the repo:

- Open the Terminal App
- `cd` to the parent directory where the repo directory will live
- `git clone https://github.com/forcedotcom/SalesforceMobileSDK-iOS-Hybrid.git`

After cloning the repo:

- `cd SalesforceMobileSDK-iOS-Hybrid`
- `./install.sh`

This script pulls the submodule dependencies from GitHub, to finalize setup of the workspace.  You can then work with the Mobile SDK by opening `SalesforceMobileSDK-Hybrid.xcworkspace` from Xcode.

The Salesforce Mobile SDK for iOS requires iOS 11.0 or greater.  The install.sh script checks for this, and aborts if the configured SDK version is incorrect.  Building from the command line has been tested using ant 1.8.  Older versions might work, but we recommend using the latest version of ant.

Introduction
==

### What's New in 7.1

**Version Updates**
- Cordova for iOS: 5.0.0
- SQLCipher: 4.0.1

Documentation
==

* Salesforce Mobile SDK Development Guide -- [HTML](https://developer.salesforce.com/docs/atlas.en-us.mobile_sdk.meta/mobile_sdk/preface_intro.htm)
* [Mobile SDK Trail](https://trailhead.salesforce.com/trails/mobile_sdk_intro)

Discussion
==
If you would like to make suggestions, have questions, or encounter any issues, we'd love to hear from you. Post any feedback you have on [Salesforce StackExchange](https://salesforce.stackexchange.com/questions/tagged/mobilesdk).
