import SwiftUI

struct DebugPanelView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LobbyDriverView(viewModel: viewModel)
                .navigationTitle("Debug HUD")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
