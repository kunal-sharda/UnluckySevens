import Foundation
import ProjectDescription

let localSigningXcconfigPath = "Config/LocalSigning.xcconfig"
let appIconSettings: SettingsDictionary = [
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
]
let localSigningSettings: Settings? = {
    let absolutePath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(localSigningXcconfigPath)
        .path

    guard FileManager.default.fileExists(atPath: absolutePath) else {
        return nil
    }

    return .settings(
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
            dependencies: [
                .package(product: "ULS_CoreGame"),
                .package(product: "ULS_Transport"),
            ],
            settings: localSigningSettings
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
                "MessagesExtension/Sources/Presentation/**",
                "MessagesExtension/Sources/Board/GameBoardCameraController.swift",
                "MessagesExtension/Sources/Board/GameBoardLayout.swift",
                "MessagesExtension/Sources/Board/GameBoardPalette.swift",
                "MessagesExtension/Sources/Board/GameBoardRenderModel.swift",
                "MessagesExtension/Sources/Board/GameBoardRenderModelBuilder.swift",
                "MessagesExtension/Sources/Board/GameBoardScene.swift",
                "MessagesExtension/Sources/Board/GameBoardSnapshotRenderer.swift",
                "MessagesExtension/Sources/Board/GameBoardSnapshotVariant.swift",
                "MessagesExtension/Sources/Board/GameBoardTarget.swift",
            ],
            dependencies: [
                .package(product: "ULS_CoreGame"),
                .package(product: "ULS_Transport"),
            ]
        ),
    ]
)
