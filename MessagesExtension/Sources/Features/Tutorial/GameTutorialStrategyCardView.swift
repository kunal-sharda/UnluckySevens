import SwiftUI

struct GameTutorialStrategyCardView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 13) {
                Text("PLAYER AID")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(GameTheme.mutedInk)

                Text("Strategy")
                    .font(GameTheme.titleFont)
                    .foregroundStyle(GameTheme.ink)
                    .accessibilityAddTraits(.isHeader)

                Rectangle()
                    .fill(GameTheme.outline.opacity(0.42))
                    .frame(height: 1)

                tip(
                    title: "Read the dots",
                    description: "More dots mean more rolls and more resources.",
                    icon: probabilityToken
                )

                tip(
                    title: "Spend for points",
                    description: "Roads open settlement spots. Roads and knights can earn 2-point awards.",
                    icon: Image(systemName: "arrow.triangle.branch")
                )

                tip(
                    title: "Know the score",
                    description: "Settlement 1 · City 2 · Award 2. First to 10 wins.",
                    icon: Image(systemName: "star.fill")
                )
            }
            .padding(.horizontal, 17)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(GameTheme.surface, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(GameTheme.outline.opacity(0.72), lineWidth: 1.5)
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
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 11) {
                icon
                    .foregroundStyle(GameTheme.accent)
                    .frame(width: 34, height: 34)
                    .accessibilityHidden(true)

                Text(title)
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.ink)
            }

            Text(description)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
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
