import SwiftUI

struct GameTutorialPreferenceControls: View {
    let onDisableTip: () -> Void
    let onDisableAll: () -> Void
    let accessibilityPrefix: String
    let disableAllIdentifier: String

    var body: some View {
        VStack(spacing: 0) {
            preferenceButton("Don't show this tip again", action: onDisableTip)
                .accessibilityIdentifier("\(accessibilityPrefix).disableTip")
            preferenceButton("Disable all tutorial tips", action: onDisableAll)
                .accessibilityIdentifier(disableAllIdentifier)
        }
    }

    private func preferenceButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.footnote)
                .underline()
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
