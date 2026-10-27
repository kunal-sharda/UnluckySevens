import SwiftUI

struct GameTutorialPreferenceControls: View {
    let onDisableTip: () -> Void
    let onDisableAll: () -> Void
    let accessibilityPrefix: String
    let disableAllIdentifier: String
    var onEnableTip: () -> Void = {}
    @State private var hidesTip = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { tipButton; Spacer(minLength: 0); allButton }
            VStack(alignment: .leading, spacing: 4) { tipButton; allButton }
        }
    }

    private var tipButton: some View {
        Button {
            hidesTip.toggle()
            if hidesTip { onDisableTip() } else { onEnableTip() }
        } label: {
            Label("Hide this tip", systemImage: hidesTip ? "checkmark.square.fill" : "square")
                .font(.footnote)
                .fixedSize(horizontal: true, vertical: false)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(hidesTip ? "Checked" : "Unchecked")
        .accessibilityHint("Controls whether this topic appears next time. You can restore it in Settings.")
        .accessibilityIdentifier("\(accessibilityPrefix).disableTip")
    }

    private var allButton: some View {
        Button(action: onDisableAll) {
            Text("Turn off all tips")
                .font(.footnote)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 8)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(.primary.opacity(0.4)))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(disableAllIdentifier)
    }
}
