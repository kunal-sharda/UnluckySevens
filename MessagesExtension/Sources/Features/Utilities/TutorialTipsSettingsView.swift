import SwiftUI

struct TutorialTipsSettingsView: View {
    @Bindable var preferences: AppPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Individual tips").font(.headline)
                Text(preferences.tutorialPopupsEnabled
                     ? "Choose which topics appear. The Tutorial pop-ups switch in Settings controls all of them."
                     : "All tips are paused in Settings. Your choices below are remembered.")
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
