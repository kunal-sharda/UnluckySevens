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
                    field("turnStep", viewModel.turnStep)
                    field("lastRoll", viewModel.lastRoll)
                    field("pendingDiscards", viewModel.pendingDiscardRequirements)
                    field("discardStatus", viewModel.submittedDiscardsStatus)
                    field("robberReady", viewModel.robberMoveReadiness)
                    field("stealVictims", viewModel.eligibleStealVictims)
                    field("remainingPieces", viewModel.remainingPieces)
                    field("activeTrade", viewModel.activeTradeOffer)
                    field("tradeAccepts", viewModel.pendingTradeAccepts)
                    field("visibleHands", viewModel.visibleHands)
                    field("bankResources", viewModel.bankResources)
                    field("devDeckRemaining", viewModel.devDeckRemaining)
                    field("visibleDevCards", viewModel.visibleDevCards)
                    field("setupPlacement", viewModel.setupPlacement)
                    field("turnIntent", viewModel.turnIntent)
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

                        Button("Place Pair (node 0, edge 0)") {
                            viewModel.sendSetupPairIntentDebug(settlementNode: 0, roadEdge: 0)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendSetupPairIntentDebug)
                    }

                    if viewModel.isTurnSelectedState {
                        Button("Roll Dice") {
                            viewModel.sendRollDiceIntentDebug()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendRollDiceIntentDebug)

                        Button("Submit Discard") {
                            viewModel.sendSubmitDiscardIntentDebug()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendSubmitDiscardIntentDebug)

                        Button("Move Robber") {
                            viewModel.sendMoveRobberIntentDebug()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendMoveRobberIntentDebug)

                        ForEach(viewModel.stealVictimOptions, id: \.self) { victim in
                            Button("Steal From \(victim)") {
                                viewModel.sendSelectStealVictimIntentDebug(victimPlayer: victim)
                            }
                            .buttonStyle(.bordered)
                        }

                        Button("Build Road") {
                            viewModel.sendBuildRoadIntentDebug()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendBuildRoadIntentDebug)

                        Button("Build Settlement") {
                            viewModel.sendBuildSettlementIntentDebug()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendBuildSettlementIntentDebug)

                        Button("Build City") {
                            viewModel.sendBuildCityIntentDebug()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendBuildCityIntentDebug)

                        Button("Propose Trade") {
                            viewModel.sendProposeTradeIntentDebug()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendProposeTradeIntentDebug)

                        Button("Accept Trade") {
                            viewModel.sendAcceptTradeIntentDebug()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendAcceptTradeIntentDebug)

                        Button("Execute Trade Accept") {
                            viewModel.sendExecuteTradeIntentDebug()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendExecuteTradeIntentDebug)

                        Button("Buy Dev Card") {
                            viewModel.sendBuyDevCardIntentDebug()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendBuyDevCardIntentDebug)

                        Button("Play Knight") {
                            viewModel.sendPlayKnightIntentDebug()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendPlayKnightIntentDebug)

                        Button("Play Monopoly") {
                            viewModel.sendPlayMonopolyIntentDebug()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendPlayMonopolyIntentDebug)

                        Button("Play Year of Plenty") {
                            viewModel.sendPlayYearOfPlentyIntentDebug()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendPlayYearOfPlentyIntentDebug)

                        Button("Play Road Building") {
                            viewModel.sendPlayRoadBuildingIntentDebug()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendPlayRoadBuildingIntentDebug)

                        Button("Reveal VP") {
                            viewModel.sendRevealVictoryPointIntentDebug()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendRevealVictoryPointIntentDebug)

                        Button("End Turn") {
                            viewModel.sendEndTurnIntentDebug()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canSendEndTurnIntentDebug)
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
