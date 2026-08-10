import SwiftUI

struct GameTutorialStrategyCardView: View {
    var showsBackdrop = true
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        ZStack {
            if showsBackdrop {
                Color.black.opacity(0.58)
                    .ignoresSafeArea()
            }

            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: GameTheme.inlineSpacing) {
                    Text("QUICK TIPS")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(GameTheme.mutedInk)

                    Spacer()

                    if let onDismiss {
                        Button("Close Strategy", systemImage: "xmark", action: onDismiss)
                            .labelStyle(.iconOnly)
                            .font(.body.bold())
                            .foregroundStyle(GameTheme.mutedInk)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                            .accessibilityIdentifier("uls.strategy.close")
                    }
                }

                Text("Strategy")
                    .font(GameTheme.titleFont)
                    .foregroundStyle(GameTheme.ink)
                    .accessibilityAddTraits(.isHeader)

                Rectangle()
                    .fill(GameTheme.outline.opacity(0.42))
                    .frame(height: 1)

                tip(
                    title: "Follow the dots",
                    description: "More dots mean that number rolls more often. Build nearby to collect more resources.",
                    icon: probabilityToken
                )

                tip(
                    title: "Build toward points",
                    description: "Roads reach new settlement spots. Longest Road (5+) and Largest Army (3+) are worth 2 points.",
                    icon: Image(systemName: "arrow.triangle.branch")
                )

                tip(
                    title: "Race to 10",
                    description: "Settlements are 1, cities are 2, and awards are 2 points each.",
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(onDismiss != nil)
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
