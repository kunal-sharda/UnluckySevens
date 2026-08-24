import SwiftUI

struct AppSettingsView: View {
    private enum Destination: Hashable {
        case rules
    }

    @State private var path: [Destination] = []
    @State private var showsStrategy = false
    @Bindable var preferences: AppPreferences
    let summary: GameSettingsSummary
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.30)
                .ignoresSafeArea()

            NavigationStack(path: $path) {
                VStack(spacing: 0) {
                    titleBar

                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 0) {
                            skipAnimationsRow
                            divider
                            currentGameSection
                            divider
                            rulesRow
                            divider
                            privacyPolicyRow
                        }
                        .padding(16)
                    }
                }
                .background(GameTheme.feltRaised)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Destination.self) { destination in
                    switch destination {
                    case .rules:
                        GameRulesReferenceView {
                            showsStrategy = true
                        }
                    }
                }
            }
            .frame(maxWidth: 420, maxHeight: 440)
            .background(GameTheme.feltRaised)
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
            .overlay {
                RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                    .stroke(GameTheme.surface.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.28), radius: 10, y: 6)
            .padding(24)
            .allowsHitTesting(!showsStrategy)
            .accessibilityHidden(showsStrategy)

            if showsStrategy {
                GameTutorialStrategyCardView(onDismiss: dismissStrategy)
                    .zIndex(1)
            }
        }
        .tint(GameTheme.accent)
        .accessibilityIdentifier("uls.settings.surface")
    }

    private func dismissStrategy() {
        showsStrategy = false
    }

    private var titleBar: some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            Text("Settings")
                .font(GameTheme.titleFont)
                .foregroundStyle(GameTheme.surface)

            Spacer()

            Button("Done", action: onDismiss)
                .font(GameTheme.bodyFont.bold())
                .foregroundStyle(GameTheme.accent)
                .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .background(GameTheme.felt)
    }

    private var skipAnimationsRow: some View {
        Toggle(isOn: $preferences.skipsAnimations) {
            Text("Skip animations")
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.surface)
        }
        .tint(GameTheme.accent)
        .padding(.vertical, 18)
        .frame(minHeight: 60)
        .accessibilityIdentifier("uls.settings.skipAnimations")
    }

    private var currentGameSection: some View {
        settingsSection(title: "Current game") {
            VStack(spacing: 0) {
                factRow("Rules", value: summary.rules)
                divider
                factRow("Board", value: summary.board)
                divider
                factRow("Victory", value: summary.victory)
            }
        }
    }

    private var rulesRow: some View {
        NavigationLink(value: Destination.rules) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Rules")
                        .font(GameTheme.headingFont)
                        .foregroundStyle(GameTheme.surface)
                    Text("Setup, turns, trading, and winning")
                        .font(GameTheme.metaFont)
                        .foregroundStyle(GameTheme.surface.opacity(0.72))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(GameTheme.surface.opacity(0.58))
            }
            .frame(minHeight: 60)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier("uls.settings.showRules")
    }

    private var privacyPolicyRow: some View {
        Link(destination: AppWebLinks.privacyPolicyURL) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Privacy Policy")
                        .font(GameTheme.headingFont)
                        .foregroundStyle(GameTheme.surface)
                    Text("How Unlucky Sevens handles your data")
                        .font(GameTheme.metaFont)
                        .foregroundStyle(GameTheme.surface.opacity(0.72))
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(GameTheme.surface.opacity(0.58))
            }
            .frame(minHeight: 60)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .accessibilityHint("Opens in your browser")
        .accessibilityIdentifier("uls.settings.privacyPolicy")
    }

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(GameTheme.metaFont.bold())
                .foregroundStyle(GameTheme.surface.opacity(0.68))
            content()
        }
        .padding(.vertical, 10)
    }

    private func factRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(GameTheme.surface.opacity(0.84))
            Spacer()
            Text(value)
                .font(GameTheme.bodyFont.bold())
                .foregroundStyle(GameTheme.surface)
        }
        .font(GameTheme.bodyFont)
        .frame(minHeight: 40)
    }

    private var divider: some View {
        Rectangle()
            .fill(GameTheme.surface.opacity(0.14))
            .frame(height: 1)
    }
}
