import SwiftUI

struct DebugHUDView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label("Debug", systemImage: "ladybug.fill")
                .font(GameTheme.metaFont.weight(.semibold))
                .foregroundStyle(GameTheme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(GameTheme.surface.opacity(0.94))
                )
                .overlay(
                    Capsule()
                        .stroke(GameTheme.outline.opacity(0.16), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the development-only debug tools")
        .sheet(isPresented: $isPresented) {
            DebugPanelView(viewModel: viewModel)
        }
    }
}
