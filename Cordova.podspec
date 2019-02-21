Pod::Spec.new do |s|
  s.name         = "Cordova"
  s.version      = "5.0.0"
  s.summary      = "Cordova for iOS"
  s.homepage     = "https://github.com/apache/cordova-ios"
  s.license      = { :type => "Apache 2.0", :file => "LICENSE" }
  s.author       = { "Bharath Hariharan" => "bhariharan@salesforce.com" }
  s.platform     = :ios, "11.0"
  s.source       = { :git => "https://github.com/apache/cordova-ios.git",
                     :tag => "{s.version}",
                     :submodules => true }
  s.requires_arc = true
  s.default_subspec  = 'Cordova'
  s.subspec 'Cordova' do |cordova|
      cordova.source_files = 'external/cordova-ios/cordova-ios/CordovaLib/Classes/**/*.{h,m}', 'external/cordova-ios/cordova-ios/CordovaLib/Cordova/Cordova.h'
      cordova.public_header_files = 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDV.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVAppDelegate.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVAvailability.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVAvailabilityDeprecated.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVCommandDelegate.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVCommandDelegateImpl.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVCommandQueue.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVConfigParser.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVInvokedUrlCommand.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVPlugin+Resources.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVPlugin.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVPluginResult.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVScreenOrientationDelegate.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVTimer.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVURLProtocol.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVUserAgentUtil.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVViewController.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVWebViewEngineProtocol.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/CDVWhitelist.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/NSDictionary+CordovaPreferences.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Public/NSMutableArray+QueueAdditions.h', 'external/cordova-ios/cordova-ios/CordovaLib/Classes/Private/Plugins/CDVUIWebViewEngine/CDVUIWebViewDelegate.h', 'external/cordova-ios/cordova-ios/CordovaLib/Cordova/Cordova.h'
      cordova.prefix_header_contents = ''
      cordova.requires_arc = true
  end
end

#
# ATTENTION: 
#
# This file needs to be updated manually whenever a Cordova upgrade is performed.
# Sections that need to be updated:
#   1. {s.version} should be the latest version of Cordova.
#   2. {s.platform} should be updated if the minimum version of iOS has changed.
#   3. {cordova.source_files} should be updated if the path of the library has changed.
#   4. {cordova.public_header_files} should be updated, by removing the public headers
#      that have been removed and adding the public headers that have been added.
#
# Once Cordova accepts the upstream PR and maintains its own pod specs, this file may be removed.
#
# Upstream Cordova GitHub Issue: https://github.com/apache/cordova-ios/issues/542
# Upstream Cordova GitHub PR: https://github.com/apache/cordova-ios/pull/543
#