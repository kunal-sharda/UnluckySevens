import SwiftUI

struct GameRulesReferenceView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 18) {
                rule("Objective", icon: "flag.checkered", text: "Be the first player to reach 10 victory points on your turn.")
                rule("Setup", icon: "map.fill", text: "Place a settlement and connected road twice. The player order reverses for the second round, and your second settlement grants resources from adjacent tiles.")
                rule("Turn sequence", icon: "arrow.trianglehead.2.clockwise.rotate.90", text: "Play an eligible development card, roll, trade and build in any order, then end your turn.")
                rule("Production", icon: "dice.fill", text: "Settlements gain one resource and cities gain two when an adjacent number rolls. The robber blocks its tile.")
                buildCosts
                rule("Trading", icon: "arrow.left.arrow.right", text: "Trade with players or the bank. Ports improve 4:1 trades to 3:1 or a matching 2:1.")
                rule("Seven and the robber", icon: "hand.raised.fill", text: "Hands above seven discard half, rounded down. Move the robber, then steal from an eligible opponent.")
                rule("Development cards", icon: "rectangle.stack.fill", text: "Play at most one non-VP card per turn. Newly bought cards wait until a later turn.")
                rule("Awards and winning", icon: "trophy.fill", text: "Settlements score 1 VP and cities score 2. Longest Road and Largest Army add 2 VP each. First to 10 wins.")
            }
            .padding(GameTheme.shellPadding)
        }
        .background(GameTheme.appBackground.ignoresSafeArea())
        .navigationTitle("Rules")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(GameTheme.felt, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .accessibilityIdentifier("uls.rules.surface")
    }

    private var buildCosts: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Build costs", icon: "hammer.fill")
            cost("Road", "1 wood · 1 brick")
            cost("Settlement", "wood · brick · sheep · wheat")
            cost("City", "3 ore · 2 wheat")
            cost("Development card", "sheep · wheat · ore")
        }
    }

    private func rule(_ title: String, icon: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle(title, icon: icon)
            Text(text)
                .font(GameTheme.bodyFont)
                .foregroundStyle(GameTheme.surface.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(GameTheme.headingFont)
            .foregroundStyle(GameTheme.accent)
    }

    private func cost(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .fontWeight(.semibold)
            Spacer(minLength: 12)
            Text(value)
                .foregroundStyle(GameTheme.surface.opacity(0.72))
                .multilineTextAlignment(.trailing)
        }
        .font(GameTheme.metaFont)
        .foregroundStyle(GameTheme.surface)
    }
}
