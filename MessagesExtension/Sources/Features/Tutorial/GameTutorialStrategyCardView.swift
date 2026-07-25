import SwiftUI

struct GameTutorialStrategyCardView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Strategy")
                    .font(GameTheme.titleFont)
                    .foregroundStyle(GameTheme.ink)
                    .accessibilityAddTraits(.isHeader)

                tip(
                    title: "Read the dots",
                    description: "More dots under a number mean a stronger spot for that resource. Cover several resources when you can.",
                    icon: probabilityToken
                )

                tip(
                    title: "Spend for points",
                    description: "Roads open new settlement spots and can earn Longest Road. Knights build toward Largest Army. Victory Point cards score 1.",
                    icon: Image(systemName: "arrow.triangle.branch")
                )

                tip(
                    title: "Know the score",
                    description: "Cities, Longest Road, and Largest Army are worth 2 points. Settlements are worth 1 point each.",
                    icon: Image(systemName: "star.fill")
                )
            }
            .padding(18)
            .frame(maxWidth: 340, alignment: .leading)
            .background(GameTheme.surface, in: RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
            .overlay {
                RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                    .stroke(GameTheme.outline.opacity(0.48), lineWidth: 1)
            }
            .padding(.horizontal, 22)
        }
        .allowsHitTesting(false)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.tutorial.strategyCard")
    }

    private func tip<Icon: View>(
        title: String,
        description: String,
        icon: Icon
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            icon
                .foregroundStyle(GameTheme.accent)
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.ink)

                Text(description)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var probabilityToken: some View {
        VStack(spacing: 1) {
            Text("8")
                .font(.headline.bold())

            HStack(spacing: 1.5) {
                ForEach(0..<5, id: \.self) { _ in
                    Circle()
                        .frame(width: 3, height: 3)
                }
            }
        }
    }
}
