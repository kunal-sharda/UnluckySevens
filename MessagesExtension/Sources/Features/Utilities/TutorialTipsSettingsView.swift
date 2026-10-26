import SwiftUI

struct TutorialTipsSettingsView: View {
    @Bindable var preferences: AppPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Tutorial pop-ups", isOn: $preferences.tutorialPopupsEnabled)
                    .accessibilityIdentifier("uls.settings.tips.master")
                Text(preferences.tutorialPopupsEnabled
                     ? "Choose which tips appear. Closing a tip keeps it enabled for next time."
                     : "All tips are paused. Turn on tutorial pop-ups to show your selected tips.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(GameTutorialTip.allCases) { tip in
                    Toggle(tip.title, isOn: binding(for: tip))
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("uls.settings.tip.\(tip.rawValue)")
                }
                Button("Enable all tips") { preferences.enableAllTutorialTips() }
                    .buttonStyle(GameTabletopActionButtonStyle(emphasis: .secondary, solidBackground: true))
                    .accessibilityIdentifier("uls.settings.tips.enableAll")
            }
            .font(GameTheme.bodyFont)
            .foregroundStyle(GameTheme.surface)
            .padding(16)
        }
        .accessibilityIdentifier("uls.settings.tips.list")
        .background(GameTheme.feltRaised)
        .navigationTitle("Tutorial Tips")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(GameTheme.felt, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func binding(for tip: GameTutorialTip) -> Binding<Bool> {
        Binding(get: { preferences.isTipEnabled(tip) },
                set: { preferences.setTip(tip, enabled: $0) })
    }
}
