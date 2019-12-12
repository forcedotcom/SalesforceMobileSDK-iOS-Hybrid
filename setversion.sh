#!/bin/bash

#set -x

OPT_VERSION=""
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

usage ()
{
    echo "Use this script to set Mobile SDK version number in source files"
    echo "Usage: $0 -v <version>"
    echo "  where: version is the version e.g. 8.0.0"
}

parse_opts ()
{
    while getopts v:d: command_line_opt
    do
        case ${command_line_opt} in
            v)  OPT_VERSION=${OPTARG};;
        esac
    done

    if [ "${OPT_VERSION}" == "" ]
    then
        echo -e "${RED}You must specify a value for the version.${NC}"
        usage
        exit 1
    fi
}

# Helper functions
update_podspec ()
{
    local file=$1
    local version=$2
    gsed -i "s/s\.version.*=.*$/s.version      = \"${version}\"/g" ${file}
}

update_test_cordova_plugin_js ()
{
    local file=$1
    local version=$2
    gsed -i "s/\"com.salesforce\":.*\"[^\"]*\"/\"com.salesforce\": \"${version}\"/g" ${file}
}

parse_opts "$@"

echo -e "${YELLOW}*** SETTING VERSION TO ${OPT_VERSION} ***${NC}"

echo "*** Updating podspecs ***"
update_podspec "./SalesforceFileLogger.podspec" "${OPT_VERSION}"
update_podspec "./SalesforceHybridSDK.podspec" "${OPT_VERSION}"

echo "*** Updating cordova_plugins.js for tests ***"
update_test_cordova_plugin_js "./libs/SalesforceHybridSDK/SalesforceHybridSDKTestApp/cordova_plugins.js" "${OPT_VERSION}"

