import SwiftUI

struct GameReferenceButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Reference")
                .font(.caption.weight(.semibold))
                .foregroundStyle(GameTheme.felt)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(GameTheme.surface, in: RoundedRectangle(cornerRadius: 4))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Learn and Reference")
        .accessibilityHint("Opens costs, rules and learning while preserving your place")
        .accessibilityIdentifier("uls.tabletop.reference")
    }
}
