import ProjectDescription

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
                    "UILaunchScreen": .dictionary([:]),
                ]
            ),
            sources: ["App/Sources/**"],
            dependencies: [
                .target(name: "MessagesExtension")
            ]
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
            ]
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
