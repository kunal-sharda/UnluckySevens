import SwiftUI

struct LobbyGameSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Selected rules") {
                    LabeledContent("Rules", value: "Standard")
                    LabeledContent("Board", value: "Balanced")
                    LabeledContent("Victory", value: "10 points")
                }
            }
            .navigationTitle("Game settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
