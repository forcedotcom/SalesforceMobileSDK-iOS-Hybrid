#!/bin/bash

# set -x

#
# Run this script before working with the SalesforceMobileSDK-Hybrid Xcode workspace.
#

# Sync submodules
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"
git submodule init
git submodule sync
git submodule update --init --recursive

# Create test_credentials.json if needed to avoid build errors
if [ ! -f "shared/test/test_credentials.json" ]
then
    cp shared/test/test_credentials.json.sample shared/test/test_credentials.json
fi

# Prepare cordova.js
cd external/cordova
npm install
npm run prepare
