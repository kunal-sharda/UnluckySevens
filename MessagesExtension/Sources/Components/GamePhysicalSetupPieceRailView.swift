import SwiftUI

struct GamePhysicalSetupPieceRailView: View {
    let model: GameSetupPlacementModel
    let playerColor: Color

    var body: some View {
        HStack(spacing: 44) {
            piece(
                kind: .settlement,
                title: "Settlement",
                number: "1",
                accessibilityIdentifier: "uls.setup.piece.settlement",
                isActive: model.isLocalPlayerActive && model.piece == .settlement,
                isComplete: model.piece == .road || model.piece == .done
            )

            piece(
                kind: .road,
                title: "Road",
                number: "1",
                accessibilityIdentifier: "uls.setup.piece.road",
                isActive: model.isLocalPlayerActive && model.piece == .road,
                isComplete: model.piece == .done
            )
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.setup.pieceRail")
        .accessibilityLabel("Setup placement steps")
        .accessibilityValue("1 settlement and 1 road")
    }

    private func piece(
        kind: GameTabletopPiecePropView.Kind,
        title: String,
        number: String,
        accessibilityIdentifier: String,
        isActive: Bool,
        isComplete: Bool
    ) -> some View {
        VStack(spacing: 3) {
            ZStack(alignment: .topTrailing) {
                GameTabletopPiecePropView(
                    kind: kind,
                    color: playerColor,
                    isSelected: isActive
                )
                .frame(width: pieceWidth(for: kind), height: 34)
                .scaleEffect(isActive ? 1.12 : 1)

                Text(isComplete ? "✓" : number)
                    .font(.caption2.bold())
                    .foregroundStyle(GamePhysicalTurnPalette.cardCountInk)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(GamePhysicalTurnPalette.primaryText))
                    .overlay {
                        Circle().stroke(
                            isActive
                                ? GamePhysicalTurnPalette.selectedKeyline
                                : Color.black.opacity(0.32),
                            lineWidth: isActive ? 2 : 1
                        )
                    }
                    .offset(x: 8, y: -5)
            }
            .frame(width: 60, height: 37)

            GameTabletopNameTileView(
                title: title,
                width: 92,
                isSelected: isActive
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValue(isActive: isActive, isComplete: isComplete))
        .accessibilityIdentifier(accessibilityIdentifier)
        .gameTutorialTarget(kind == .road ? .setupRoadPiece : .setupSettlementPiece)
    }

    private func accessibilityValue(isActive: Bool, isComplete: Bool) -> String {
        if isActive { return "Place now" }
        if isComplete { return "Complete" }
        return model.isLocalPlayerActive ? "Next" : "Waiting"
    }

    private func pieceWidth(for kind: GameTabletopPiecePropView.Kind) -> CGFloat {
        switch kind {
        case .road: return 54
        case .settlement, .city: return 42
        }
    }
}
