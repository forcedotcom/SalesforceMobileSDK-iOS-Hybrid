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
      cordova.source_files = 'libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/**/*.{h,m}', 'libs/SalesforceHybridSDK/SalesforceHybridSDK/SalesforceHybridSDK.h'
      cordova.public_header_files = 'libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/Plugins/SFAdditions/CDVPlugin+SFAdditions.h', 'libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/Plugins/SFAccountManagerPlugin/SFAccountManagerPlugin.h', 'libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/Plugins/SFForcePlugin/SFForcePlugin.h', 'libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/SFHybridViewConfig.h', 'libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/SFHybridViewController.h', 'libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/SFLocalhostSubstitutionCache.h', 'libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/Plugins/SFNetworkPlugin/SFNetworkPlugin.h', 'libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/SFSDKHybridLogger.h', 'libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/Plugins/SDKInfo/SFSDKInfoPlugin.h', 'libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/Plugins/SFSmartStore/SFSmartStorePlugin.h', 'libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/Plugins/SFSmartSyncPlugin/SFSmartSyncPlugin.h', 'libs/SalesforceHybridSDK/SalesforceHybridSDK/SalesforceHybridSDK.h', 'libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/SalesforceHybridSDKManager.h', 'libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/Plugins/SFOAuthPlugin/SalesforceOAuthPlugin.h'
      cordova.prefix_header_contents = ''
      cordova.requires_arc = true
  end
end
