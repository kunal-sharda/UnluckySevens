import Foundation
import ProjectDescription

let localSigningXcconfigPath = "Config/LocalSigning.xcconfig"
let appIconSettings: SettingsDictionary = [
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "CURRENT_PROJECT_VERSION": "1",
    "MARKETING_VERSION": "1.0",
    // A standalone Messages container has no executable entry point for
    // Xcode's debug-dylib trampoline.
    "ENABLE_DEBUG_DYLIB": "NO",
]
let messagesExtensionIconSettings: SettingsDictionary = [
    "ASSETCATALOG_COMPILER_APPICON_NAME": "iMessage App Icon",
    "CURRENT_PROJECT_VERSION": "1",
    "MARKETING_VERSION": "1.0",
]
let messagesExtensionSettings: Settings = {
    let absolutePath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(localSigningXcconfigPath)
        .path

    guard FileManager.default.fileExists(atPath: absolutePath) else {
        return .settings(base: messagesExtensionIconSettings, defaultSettings: .recommended)
    }

    return .settings(
        base: messagesExtensionIconSettings,
        configurations: [
            .debug(
                name: "Debug",
                xcconfig: .relativeToRoot(localSigningXcconfigPath)
            ),
            .release(
                name: "Release",
                xcconfig: .relativeToRoot(localSigningXcconfigPath)
            ),
        ],
        defaultSettings: .recommended
    )
}()
let appTargetSettings: Settings = {
    let absolutePath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(localSigningXcconfigPath)
        .path

    guard FileManager.default.fileExists(atPath: absolutePath) else {
        return .settings(base: appIconSettings, defaultSettings: .recommended)
    }

    return .settings(
        base: appIconSettings,
        configurations: [
            .debug(
                name: "Debug",
                xcconfig: .relativeToRoot(localSigningXcconfigPath)
            ),
            .release(
                name: "Release",
                xcconfig: .relativeToRoot(localSigningXcconfigPath)
            ),
        ],
        defaultSettings: .recommended
    )
}()

let project = Project(
    name: "UnluckySevens",
    packages: [
        .local(path: "Packages/ULS_CoreGame"),
        .local(path: "Packages/ULS_Transport"),
    ],
    targets: [
        .target(
            name: "UnluckySevensApp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.unluckysevens.app",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": .string("Unlucky Sevens"),
                    "CFBundleIconName": .string("AppIcon"),
                    "ITSAppUsesNonExemptEncryption": .boolean(false),
                    "UILaunchScreen": .dictionary([:]),
                ]
            ),
            resources: ["App/Resources/**"],
            dependencies: [
                .target(name: "MessagesExtension")
            ],
            settings: appTargetSettings
        ),
        .target(
            name: "MessagesExtensionSupport",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.unluckysevens.app.messagesextension.support",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: .sourceFilesList(globs: [
                .glob(
                    "MessagesExtension/Sources/**",
                    excluding: [
                        "MessagesExtension/Sources/App/MessagesHostResizeShield.swift",
                        "MessagesExtension/Sources/App/MessagesViewController.swift",
                    ]
                ),
            ]),
            dependencies: [
                .package(product: "ULS_CoreGame"),
                .package(product: "ULS_Transport"),
            ],
            settings: .settings(base: [
                "APPLICATION_EXTENSION_API_ONLY": "YES",
            ])
        ),
        .target(
            name: "MessagesExtension",
            destinations: .iOS,
            product: .messagesExtension,
            bundleId: "com.unluckysevens.app.messagesextension",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": .string("Unlucky Sevens"),
                    "NSExtension": .dictionary([
                        "NSExtensionPointIdentifier": .string("com.apple.message-payload-provider"),
                        "NSExtensionPrincipalClass": .string(
                            "$(PRODUCT_MODULE_NAME).MessagesViewController"),
                        "NSExtensionAttributes": .dictionary([
                            "MSMessagesAppPresentationStyle": .string(
                                "MSMessagesAppPresentationStyleCompact")
                        ]),
                    ]),
                ]
            ),
            sources: [
                "MessagesExtension/Sources/App/MessagesHostResizeShield.swift",
                "MessagesExtension/Sources/App/MessagesViewController.swift",
            ],
            resources: ["MessagesExtension/Resources/**"],
            dependencies: [
                .target(name: "MessagesExtensionSupport"),
            ],
            settings: messagesExtensionSettings
        ),
        .target(
            name: "MessagesExtensionTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.unluckysevens.app.messagesextension.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["MessagesExtension/Tests/**"],
            resources: ["MessagesExtension/Resources/**"],
            dependencies: [
                .target(name: "MessagesExtensionSupport"),
                .package(product: "ULS_CoreGame"),
                .package(product: "ULS_Transport"),
            ]
        ),
        .target(
            name: "UnluckySevensUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.unluckysevens.app.uitests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["UnluckySevensUITests/**"],
            dependencies: [
                .target(name: "UnluckySevensApp")
            ]
        ),
    ]
)
