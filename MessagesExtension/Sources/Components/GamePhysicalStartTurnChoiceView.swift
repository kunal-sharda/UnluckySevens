import SwiftUI

struct GamePhysicalStartTurnChoiceView: View {
    let canPlayDevCards: Bool
    let canRoll: Bool
    let isDevChooserOpen: Bool
    let onToggleDevCards: () -> Void
    let onRoll: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: isDevChooserOpen ? 38 : 54) {
            if canPlayDevCards {
                Button(action: onToggleDevCards) {
                    VStack(spacing: isDevChooserOpen ? 6 : 12) {
                        ZStack {
                            GameTabletopPortraitCardView(
                                face: .developmentBack,
                                size: cardSize,
                                stackDepth: 1
                            )
                            .rotationEffect(.degrees(-10))
                            .offset(x: -cardOffset, y: 4)

                            GameTabletopPortraitCardView(
                                face: .developmentBack,
                                size: cardSize,
                                stackDepth: 1
                            )
                            .rotationEffect(.degrees(10))
                            .offset(x: cardOffset)
                        }
                        .frame(width: isDevChooserOpen ? 72 : 104, height: isDevChooserOpen ? 62 : 92)

                        GameTabletopNameTileView(
                            title: "Dev Cards",
                            width: isDevChooserOpen ? 72 : 82,
                            isSelected: isDevChooserOpen
                        )
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(minWidth: 108, minHeight: isDevChooserOpen ? 92 : 132)
                .accessibilityIdentifier("uls.startTurn.devCards")
                .accessibilityLabel("Dev Cards")
                .accessibilityHint(
                    isDevChooserOpen
                        ? "Closes the pre-roll Dev Card chooser"
                        : "Opens playable pre-roll Dev Cards"
                )
                .accessibilityAddTraits(isDevChooserOpen ? .isSelected : [])
            }

            if canRoll {
                Button(action: onRoll) {
                    VStack(spacing: isDevChooserOpen ? 5 : 10) {
                        GamePhysicalDicePairView(isRolling: false)
                            .scaleEffect(isDevChooserOpen ? 0.88 : 1.16)
                            .frame(height: isDevChooserOpen ? 62 : 92)

                        GameTabletopNameTileView(
                            title: "Roll Dice",
                            width: 76,
                            isSelected: true
                        )
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(minWidth: 122, minHeight: isDevChooserOpen ? 92 : 132)
                .accessibilityIdentifier("uls.startTurn.roll")
                .accessibilityLabel("Roll dice")
                .accessibilityValue("Ready to roll")
                .accessibilityHint("Opens the full-screen dice bowl and rolls the dice")
                .gameTutorialTarget(.rollButton)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var cardSize: CGSize {
        isDevChooserOpen
            ? CGSize(width: 39, height: 51)
            : CGSize(width: 52, height: 68)
    }

    private var cardOffset: CGFloat {
        isDevChooserOpen ? 9 : 14
    }
}
