import SwiftUI

struct AppSettingsView: View {
    private enum Destination: Hashable {
        case rules
    }

    @Bindable var preferences: AppPreferences
    let summary: GameSettingsSummary
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.30)
                .ignoresSafeArea()

            NavigationStack {
                VStack(spacing: 0) {
                    titleBar

                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 15) {
                            experienceSection
                            currentGameSection
                            helpSection
                        }
                        .padding(16)
                    }
                }
                .background(GameTheme.feltRaised)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Destination.self) { destination in
                    switch destination {
                    case .rules:
                        GameRulesReferenceView()
                    }
                }
            }
            .frame(maxWidth: 440, maxHeight: 500)
            .background(GameTheme.feltRaised)
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
            .shadow(color: .black.opacity(0.30), radius: 8, y: 5)
            .padding(24)
        }
        .tint(GameTheme.accent)
        .accessibilityIdentifier("uls.settings.surface")
    }

    private var titleBar: some View {
        HStack(spacing: 12) {
            Label("Settings", systemImage: "gearshape.fill")
                .font(GameTheme.titleFont)
                .foregroundStyle(GameTheme.surface)

            Spacer()

            Button("Done", action: onDismiss)
                .font(GameTheme.chipFont)
                .foregroundStyle(GameTheme.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(GameTheme.accent, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .background(GameTheme.felt)
    }

    private var experienceSection: some View {
        settingsSection(title: "Experience", systemImage: "sparkles") {
            Toggle(isOn: $preferences.skipsAnimations) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Skip animations")
                        .font(GameTheme.headingFont)
                        .foregroundStyle(GameTheme.surface)
                    Text("Show game changes immediately. Rules and dice results stay the same.")
                        .font(GameTheme.metaFont)
                        .foregroundStyle(GameTheme.surface.opacity(0.84))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(GameTheme.accent)
            .frame(minHeight: 52)
            .accessibilityIdentifier("uls.settings.skipAnimations")
        }
    }

    private var currentGameSection: some View {
        settingsSection(title: "Current game", systemImage: "map.fill") {
            VStack(spacing: 0) {
                factRow("Rules", value: summary.rules)
                divider
                factRow("Board", value: summary.board)
                divider
                factRow("Victory", value: summary.victory)
            }
        }
    }

    private var helpSection: some View {
        settingsSection(title: "Help", systemImage: "questionmark.circle.fill") {
            NavigationLink(value: Destination.rules) {
                HStack(spacing: 12) {
                    Image(systemName: "book.closed.fill")
                    Text("Show rules")
                        .font(GameTheme.headingFont)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.bold))
                }
                .foregroundStyle(GameTheme.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 52)
                .background(GameTheme.surface, in: RoundedRectangle(cornerRadius: 9))
            }
            .accessibilityIdentifier("uls.settings.showRules")
        }
    }

    private func settingsSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: systemImage)
                .font(GameTheme.chipFont)
                .foregroundStyle(GameTheme.accent)
            content()
        }
    }

    private func factRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(GameTheme.surface.opacity(0.84))
            Spacer()
            Text(value)
                .fontWeight(.semibold)
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
