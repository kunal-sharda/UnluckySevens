import SwiftUI

struct GameTabletopBankStackView: View {
    let chip: GameBankChip
    let showsCount: Bool

    init(chip: GameBankChip, showsCount: Bool = true) {
        self.chip = chip
        self.showsCount = showsCount
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(chip.resource.tabletopCardFill.opacity(0.70))
                .offset(x: -2.5, y: -2.5)

            RoundedRectangle(cornerRadius: 6)
                .fill(chip.resource.tabletopCardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(chip.resource.tabletopEdge.opacity(0.88), lineWidth: 1)
                )

            VStack(spacing: 2) {
                Image(chip.resource.tabletopStampAssetName)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                if showsCount {
                    Text("\(chip.count)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(chip.resource.tabletopCountInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .frame(width: 38, height: 47)
        .shadow(color: .black.opacity(0.14), radius: 2, x: 0, y: 1)
        .accessibilityHidden(true)
    }
}
