// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SalesforceMobileSDK-iOS-Hybrid",
    platforms: [
        .iOS(.v18),
        .visionOS(.v2),
        .macCatalyst(.v13)
    ],
    products: [
        .library(name: "SalesforceFileLogger", targets: ["SalesforceFileLogger"])
    ],
    dependencies: [
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack.git", exact: "3.9.1"),
        .package(url: "https://github.com/forcedotcom/SalesforceMobileSDK-iOS-SPM.git", exact: "14.0.0")
    ],
    targets: [
        .target(
            name: "SalesforceFileLogger",
            dependencies: [
                .product(name: "CocoaLumberjack", package: "CocoaLumberjack"),
                .product(name: "SalesforceSDKCommon", package: "SalesforceMobileSDK-iOS-SPM")
            ],
            path: "libs/SalesforceFileLogger/SalesforceFileLogger",
            sources: [
                "Classes/Logger/SFSDKFileLogger.m",
                "Classes/Logger/SFSDKLogFileManager.m",
                "Classes/Logger/SFSDKLogger.m"
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        )
    ]
)
