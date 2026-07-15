import SwiftUI

struct GameTabletopBankRackView: View {
    let model: GameBankTrayModel
    let showsBankCounts: Bool
    let isBankOpen: Bool
    let devDeckCount: Int
    let isDevDeckEnabled: Bool
    let onOpenBank: () -> Void
    let onOpenDevCards: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 14) {
            Button(action: onOpenBank) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 5) {
                        Text("Bank")

                        if isBankOpen {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                        }
                    }
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(GameTheme.surface.opacity(0.88))

                    HStack(spacing: 5) {
                        ForEach(model.chips) { chip in
                            GameTabletopBankStackView(
                                chip: chip,
                                showsCount: showsBankCounts
                            )
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("uls.tabletop.bankRack")
            .accessibilityLabel(bankAccessibilityLabel)
            .accessibilityHint(
                showsBankCounts
                    ? "Opens the bank"
                    : (isBankOpen ? "Hides remaining resource cards" : "Shows remaining resource cards")
            )
            .accessibilityAddTraits(isBankOpen ? .isSelected : [])

            Spacer(minLength: 0)

            Group {
                if isDevDeckEnabled {
                    Button(action: onOpenDevCards) {
                        devDeckLabel
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("uls.tabletop.devDeck")
                    .accessibilityLabel("Buy development card, \(devDeckCount) cards remaining")
                    .accessibilityHint("Buys one card for one sheep, one wheat, and one ore")
                } else {
                    devDeckLabel
                        .accessibilityElement(children: .ignore)
                        .accessibilityIdentifier("uls.tabletop.devDeck")
                        .accessibilityLabel("Draw pile, \(devDeckCount) cards remaining")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var bankAccessibilityLabel: String {
        guard showsBankCounts else {
            return "Bank"
        }
        let counts = model.chips
            .map { "\($0.resource.shortLabel) \($0.count)" }
            .joined(separator: ", ")
        return "Bank, \(counts)"
    }

    private var devDeckLabel: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text("Draw Pile")
                Text("\(devDeckCount)")
                    .monospacedDigit()
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(GameTheme.surface.opacity(0.88))

            TabletopDevDeckView(size: CGSize(width: 42, height: 50))
        }
        .frame(minWidth: 64, minHeight: 60)
    }
}
