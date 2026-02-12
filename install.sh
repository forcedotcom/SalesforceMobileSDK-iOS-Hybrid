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
git submodule update

# Restore bootconfig.json in shared submodule to committed placeholders
git -C external/shared checkout -- samples/mobilesyncexplorer/bootconfig.json samples/accounteditor/bootconfig.json 2>/dev/null || true

# Create test_credentials.json if needed to avoid build errors
if [ ! -f "shared/test/test_credentials.json" ]
then
    cp shared/test/test_credentials.json.sample shared/test/test_credentials.json
fi

# Prepare cordova.js
pushd "external/cordova"
npm install
npm run prepare
popd

# Substitute env vars if set in bootconfig.json
BOOTCONFIG_JSON_PATHS=(
    "external/shared/samples/mobilesyncexplorer/bootconfig.json"
    "external/shared/samples/accounteditor/bootconfig.json"
)
for bootconfig in "${BOOTCONFIG_JSON_PATHS[@]}"; do
    if [ -n "${MSDK_IOS_REMOTE_ACCESS_CONSUMER_KEY:-}" ]; then
        gsed -i "s|__CONSUMER_KEY__|${MSDK_IOS_REMOTE_ACCESS_CONSUMER_KEY}|g" "$bootconfig"
    fi
    if [ -n "${MSDK_IOS_REMOTE_ACCESS_CALLBACK_URL:-}" ]; then
        gsed -i "s|__REDIRECT_URI__|${MSDK_IOS_REMOTE_ACCESS_CALLBACK_URL}|g" "$bootconfig"
    fi
done

if [ -z "${MSDK_IOS_REMOTE_ACCESS_CONSUMER_KEY:-}" ] || [ -z "${MSDK_IOS_REMOTE_ACCESS_CALLBACK_URL:-}" ]; then
    echo ""
    echo "Note: MSDK_IOS_REMOTE_ACCESS_CONSUMER_KEY and/or MSDK_IOS_REMOTE_ACCESS_CALLBACK_URL are not set."
    echo "To run the sample applications, define these environment variables or ensure bootconfig.json"
    echo "files have remoteAccessConsumerKey and oauthRedirectURI set."
    echo ""
fi
