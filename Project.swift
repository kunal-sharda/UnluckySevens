import Foundation
import ProjectDescription

let localSigningXcconfigPath = "Config/LocalSigning.xcconfig"
let appIconSettings: SettingsDictionary = [
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
]
let messagesExtensionIconSettings: SettingsDictionary = [
    "ASSETCATALOG_COMPILER_APPICON_NAME": "iMessage App Icon",
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
            sources: ["MessagesExtension/Sources/**"],
            resources: ["MessagesExtension/Resources/**"],
            dependencies: [
                .package(product: "ULS_CoreGame"),
                .package(product: "ULS_Transport"),
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
            sources: [
                "MessagesExtension/Tests/**",
                "MessagesExtension/Sources/Developer/UXTestFixture.swift",
                "MessagesExtension/Sources/Developer/UXTestingAutoplayResolver.swift",
                "MessagesExtension/Sources/Presentation/**",
                "MessagesExtension/Sources/Board/GameBoardCameraController.swift",
                "MessagesExtension/Sources/Board/GameBoardLayout.swift",
                "MessagesExtension/Sources/Board/GameBoardPalette.swift",
                "MessagesExtension/Sources/Board/GamePieceGeometry.swift",
                "MessagesExtension/Sources/Board/GameBoardRenderModel.swift",
                "MessagesExtension/Sources/Board/GameBoardRenderModelBuilder.swift",
                "MessagesExtension/Sources/Board/GameBoardScene.swift",
                "MessagesExtension/Sources/Board/GameBoardSnapshotRenderer.swift",
                "MessagesExtension/Sources/Board/GameBoardSnapshotVariant.swift",
                "MessagesExtension/Sources/Board/GameBoardTarget.swift",
                "MessagesExtension/Sources/Board/GameBoardTileArt.swift",
            ],
            resources: ["MessagesExtension/Resources/**"],
            dependencies: [
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
