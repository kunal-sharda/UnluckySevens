import SwiftUI

struct DebugHUDView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var isPresented = false

    var body: some View {
        Button("Open Debug HUD", systemImage: "ladybug.fill") {
            isPresented = true
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                LobbyDriverView(viewModel: viewModel)
                    .navigationTitle("Debug HUD")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
