import SwiftUI

struct LobbyDriverView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Unlucky Sevens Lobby Driver")
                    .font(.headline)

                Text("Selection: \(viewModel.selectionStatus)")
                    .font(.subheadline)

                Group {
                    field("kind", viewModel.kind)
                    field("gameId", viewModel.gameId)
                    field("rev", viewModel.rev)
                    field("prevHash", viewModel.prevHash)
                    field("stateHash", viewModel.stateHash)
                    field("roster", viewModel.roster)
                    field("currentPlayer", viewModel.currentPlayer)
                    field("phase", viewModel.phase)
                    field("seed", viewModel.seed)
                    field("pendingJoiners", viewModel.pendingJoiners)
                }
                .font(.system(.caption, design: .monospaced))

                VStack(spacing: 8) {
                    Button("Invite New Game") {
                        viewModel.inviteNewGame()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canInvite)

                    Button("Join") {
                        viewModel.sendJoinIntent()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canJoin)

                    Button("Record Join") {
                        viewModel.recordJoin()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canRecordJoin)

                    Button("Start Game") {
                        viewModel.startGame()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canStartGame)

                    Button("Clear Pending Joins") {
                        viewModel.clearPendingJoins()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canClearPendingJoins)
                }
                .frame(maxWidth: .infinity)

                Text("Last error: \(viewModel.lastError)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func field(_ key: String, _ value: String) -> some View {
        Text("\(key): \(value)")
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
