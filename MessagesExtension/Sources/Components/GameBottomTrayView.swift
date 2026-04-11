import SwiftUI
import ULS_CoreGame

struct GameBottomTrayView: View {
    let handTray: GameHandTrayModel
    let bankTray: GameBankTrayModel
    let actionDock: GameActionDockModel
    let selectedKind: GameActionDockItem.Kind?
    let selectedBuildKind: GameBuildShelfItem.Kind?
    let isBuildShelfPresented: Bool
    let onSelect: (GameActionDockItem.Kind) -> Void
    let onSelectBuild: (GameBuildShelfItem.Kind) -> Void
    let onSelectBankResource: (ResourceV1) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.blockSpacing) {
            HandTrayView(model: handTray)
            if !bankTray.chips.isEmpty {
                BankTrayView(
                    model: bankTray,
                    onSelect: onSelectBankResource
                )
            }

            ActionDockView(
                model: actionDock,
                selectedKind: selectedKind,
                selectedBuildKind: selectedBuildKind,
                isBuildShelfPresented: isBuildShelfPresented,
                onSelect: onSelect,
                onSelectBuild: onSelectBuild
            )
        }
        .padding(GameTheme.compactPadding)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .fill(GameTheme.surface.opacity(0.97))
                .shadow(color: GameTheme.trayShadow, radius: 12, x: 0, y: -2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        )
    }
}
