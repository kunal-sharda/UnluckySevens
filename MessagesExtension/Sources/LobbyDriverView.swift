import SwiftUI
import ULS_CoreGame

struct LobbyDriverView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Unlucky Sevens Lobby Driver")
                    .font(.headline)

                Text("Selection: \(viewModel.selectionStatus)")
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Board Strategy")
                        .font(.subheadline)
                    Picker(
                        "Board Strategy",
                        selection: Binding(
                            get: { viewModel.boardStrategy },
                            set: { viewModel.setBoardStrategy($0) }
                        )
                    ) {
                        Text("Random (unconstrained)").tag(BoardGenStrategyV1.randomV1)
                        Text("No adjacent 6/8").tag(BoardGenStrategyV1.noRedAdjacentV1)
                    }
                    .pickerStyle(.segmented)
                }

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
                    field("diceRngState", viewModel.diceRngState)
                    field("setupPlacement", viewModel.setupPlacement)
                    field("pendingJoiners", viewModel.pendingJoiners)
                }
                .font(.system(.caption, design: .monospaced))

                if viewModel.hasBoardDebug {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Board Debug")
                            .font(.subheadline)
                        Group {
                            field("boardHash", viewModel.boardHash)
                            field("generator", viewModel.boardGenerator)
                            field("robberTile", viewModel.boardRobberTile)
                            field("resourcesByTile", viewModel.boardResourcesByTile)
                            field("numbersByTile", viewModel.boardNumbersByTile)
                            field("portsByIndex", viewModel.boardPortsByIndex)
                        }
                        .font(.system(.caption, design: .monospaced))
                    }
                }

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

                    if viewModel.isSetupSelectedState {
                        Button("Place Settlement (node 0)") {
                            viewModel.sendSetupSettlementIntentDebug(node: 0)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendSetupSettlementIntentDebug)

                        Button("Place Road (edge 0)") {
                            viewModel.sendSetupRoadIntentDebug(edge: 0)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendSetupRoadIntentDebug)
                    }

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
