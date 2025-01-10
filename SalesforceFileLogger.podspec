Pod::Spec.new do |s|

  s.name         = "SalesforceFileLogger"
  s.version      = "13.0.0"
  s.summary      = "Salesforce Mobile SDK for iOS"
  s.homepage     = "https://github.com/forcedotcom/SalesforceMobileSDK-iOS-Hybrid"

  s.license      = { :type => "Salesforce.com Mobile SDK License", :file => "LICENSE.md" }
  s.author       = { "Raj Rao" => "rao.r@salesforce.com" }

  s.platform     = :ios, "17.0"

  s.source       = { :git => "https://github.com/forcedotcom/SalesforceMobileSDK-iOS-Hybrid.git",
                     :tag => "v#{s.version}" }

  s.requires_arc = true
  s.default_subspec  = 'SalesforceFileLogger'

  s.subspec 'SalesforceFileLogger' do |filelogger|
      filelogger.dependency 'SalesforceSDKCommon', "~>#{s.version}"
      filelogger.dependency 'CocoaLumberjack', '~> 3.8.5'
      filelogger.resource_bundles = { 'SalesforceFileLogger' => [ 'libs/SalesforceFileLogger/SalesforceFileLogger/PrivacyInfo.xcprivacy' ] }
      filelogger.source_files = 'libs/SalesforceFileLogger/SalesforceFileLogger/Classes/**/*.{h,m}', 'libs/SalesforceFileLogger/SalesforceFileLogger/SalesforceFileLogger.h'
      filelogger.public_header_files = 'libs/SalesforceFileLogger/SalesforceFileLogger/Classes/Logger/SFSDKFileLogger.h', 'libs/SalesforceFileLogger/SalesforceFileLogger/Classes/Logger/SFSDKLogFileManager.h', 'libs/SalesforceFileLogger/SalesforceFileLogger/Classes/Logger/SFSDKLogger.h', 'libs/SalesforceFileLogger/SalesforceFileLogger/SalesforceFileLogger.h'
      filelogger.prefix_header_contents = ''
      filelogger.requires_arc = true
  end

end
