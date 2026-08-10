import SwiftUI

struct GameRulesReferenceView: View {
    let onShowStrategy: () -> Void

    @State private var showsScrollCue = true

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    rule("Objective", text: "Be the first player to reach 10 victory points on your turn.")
                    rule("Setup", text: "Place a settlement and connected road twice. The player order reverses for the second round, and your second settlement grants resources from adjacent tiles.")
                    rule("Turn sequence", text: "Play an eligible development card, roll, trade and build in any order, then end your turn.")
                    rule("Production", text: "Settlements gain one resource and cities gain two when an adjacent number rolls. The robber blocks its tile.")
                    buildCosts
                        .id("uls.rules.buildCosts")
                    rule("Trading", text: "Trade with players or the bank. Ports improve 4:1 trades to 3:1 or a matching 2:1.")
                    rule("Seven and the robber", text: "Hands above seven discard half, rounded down. Move the robber, then steal from an eligible opponent.")
                    rule("Development cards", text: "Play at most one non-VP card per turn. Newly bought cards wait until a later turn.")
                    rule("Awards and winning", text: "Settlements score 1 VP and cities score 2. Longest Road and Largest Army add 2 VP each. First to 10 wins.")
                    strategyButton
                }
                .padding(GameTheme.shellPadding)
                .padding(.bottom, 52)
            }
            .scrollIndicators(.visible)
            .simultaneousGesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { _ in showsScrollCue = false }
            )
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if showsScrollCue {
                    Button {
                        proxy.scrollTo("uls.rules.buildCosts", anchor: .top)
                        showsScrollCue = false
                    } label: {
                        Text("Scroll for more")
                            .font(GameTheme.metaFont.bold())
                            .foregroundStyle(GameTheme.surface)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(GameTheme.felt)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Moves to the next rules sections")
                    .accessibilityIdentifier("uls.rules.scrollCue")
                }
            }
        }
        .background(GameTheme.appBackground.ignoresSafeArea())
        .navigationTitle("Rules")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(GameTheme.felt, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .accessibilityIdentifier("uls.rules.surface")
    }

    private var strategyButton: some View {
        Button(action: onShowStrategy) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Strategy")
                        .font(GameTheme.headingFont)
                        .foregroundStyle(GameTheme.surface)
                    Text("Open the quick tips card")
                        .font(GameTheme.metaFont)
                        .foregroundStyle(GameTheme.surface.opacity(0.72))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(GameTheme.surface.opacity(0.58))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(GameTheme.feltRaised, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(GameTheme.surface.opacity(0.16), lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the Strategy quick tips card")
        .accessibilityIdentifier("uls.rules.showStrategy")
    }

    private var buildCosts: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Build costs")
            cost("Road", "1 wood · 1 brick")
            cost("Settlement", "wood · brick · sheep · wheat")
            cost("City", "3 ore · 2 wheat")
            cost("Development card", "sheep · wheat · ore")
        }
    }

    private func rule(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle(title)
            Text(text)
                .font(GameTheme.bodyFont)
                .foregroundStyle(GameTheme.surface.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
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
