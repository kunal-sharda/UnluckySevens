import SwiftUI
import ULS_CoreGame

struct LobbyDriverView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel

    // Manual QA Checklist:
    // 1) Tap a STATE bubble, open extension, and verify Active Context banner shows rev/phase/current.
    // 2) Switch Acting As to non-current player and verify current-player actions disable with reasons.
    // 3) Send a setup/turn INTENT as non-current and verify it appears in transcript with short label.
    // 4) Switch Acting As to current player, tap Apply Selected ... INTENT -> STATE, and verify rev increments.
    // 5) Send a new STATE and verify Active Context updates immediately without reselecting.
    // 6) Toggle single-session debug on/off and verify transcript threading behavior changes.
    // 7) Clear Context and verify action buttons disable with "No Active Context" reason.
    // 8) Select a newer STATE and tap Reload; verify stale warning clears.
    // 9) Confirm in-UI Debug Log appends decode/send/apply/error events.
    // 10) Confirm opponents are shown as counts only (no composition leakage).

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Unlucky Sevens Lobby Driver")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.activeContextBanner)
                        .font(.subheadline)
                    Text("Acting As: \(viewModel.actingAs)")
                        .font(.subheadline)
                    Text(viewModel.activeContextMeta)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if viewModel.staleContextWarning != "-" {
                        Text("Warning: \(viewModel.staleContextWarning)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                HStack(spacing: 8) {
                    Button("Reload Selected Bubble") {
                        viewModel.reloadSelectedBubble()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canReloadSelectedBubble)

                    Button("Clear Context") {
                        viewModel.clearActiveContext()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canClearActiveContext)
                }

                if !viewModel.actingAsOptions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Acting As")
                            .font(.subheadline)
                        Picker(
                            "Acting As",
                            selection: Binding(
                                get: { viewModel.actingAs },
                                set: { viewModel.setActingAs($0) }
                            )
                        ) {
                            ForEach(viewModel.actingAsOptions, id: \.self) { player in
                                Text(player).tag(player)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Toggle(
                    "Use single session (debug)",
                    isOn: Binding(
                        get: { viewModel.useSingleSessionDebug },
                        set: { viewModel.setUseSingleSessionDebug($0) }
                    )
                )
                .font(.subheadline)

                Text("Selection: \(viewModel.selectionStatus)")
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Transport Debug")
                        .font(.subheadline)
                    Group {
                        field("selectedTrigger", viewModel.selectedTrigger)
                        field("message", viewModel.selectedMessagePresence)
                        field("url", viewModel.selectedURLPresence)
                        field("urlString", viewModel.selectedURLString)
                        field("payloadQuery", viewModel.selectedPayloadQueryPresence)
                        field("payloadLength", viewModel.selectedPayloadLength)
                        field("summaryText", viewModel.selectedSummaryText)
                        field("layoutCaption", viewModel.selectedLayoutCaption)
                        field("session", viewModel.selectedSessionPresence)
                        field("decodeSource", viewModel.selectedDecodeSource)
                        field("decodeResult", viewModel.selectedDecodeResult)
                    }
                    .font(.system(.caption, design: .monospaced))
                }

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
                    field("maritimeTrade", viewModel.maritimeTradePreview)
                    field("largestArmy", viewModel.largestArmyStatus)
                    field("longestRoad", viewModel.longestRoadStatus)
                    field("vpTotals", viewModel.victoryPointsSummary)
                    field("gameOver", viewModel.gameOverSummary)
                    field("lastTurnRecap", viewModel.lastTurnRecapSummary)
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
                    actionButton(
                        "Invite New Game",
                        requiresCurrentPlayer: false,
                        isEnabled: viewModel.canInvite
                    ) {
                        viewModel.inviteNewGame()
                    }

                    actionButton(
                        "Join",
                        requiresCurrentPlayer: false,
                        isEnabled: viewModel.canJoin
                    ) {
                        viewModel.sendJoinIntent()
                    }

                    actionButton(
                        "Record Join",
                        requiresCurrentPlayer: false,
                        isEnabled: viewModel.canRecordJoin
                    ) {
                        viewModel.recordJoin()
                    }

                    actionButton(
                        "Start Game",
                        requiresCurrentPlayer: true,
                        isEnabled: viewModel.canStartGame
                    ) {
                        viewModel.startGame()
                    }

                    actionButton(
                        "Apply Selected Setup INTENT -> STATE",
                        requiresCurrentPlayer: true,
                        isEnabled: viewModel.canApplySelectedSetupIntentAsState
                    ) {
                        viewModel.applySelectedSetupIntentAsState()
                    }

                    actionButton(
                        "Apply Selected Turn INTENT -> STATE",
                        requiresCurrentPlayer: true,
                        isEnabled: viewModel.canApplySelectedTurnIntentAsState
                    ) {
                        viewModel.applySelectedTurnIntentAsState()
                    }

                    if viewModel.isSetupSelectedState {
                        actionButton(
                            "Place Settlement (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendSetupSettlementIntentDebug
                        ) {
                            viewModel.sendSetupSettlementIntentDebug(node: 0)
                        }

                        actionButton(
                            "Place Road (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendSetupRoadIntentDebug
                        ) {
                            viewModel.sendSetupRoadIntentDebug(edge: 0)
                        }

                        actionButton(
                            "Place Pair (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendSetupPairIntentDebug
                        ) {
                            viewModel.sendSetupPairIntentDebug(settlementNode: 0, roadEdge: 0)
                        }
                    }

                    if viewModel.isTurnSelectedState {
                        actionButton(
                            "Roll Dice (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendRollDiceIntentDebug
                        ) {
                            viewModel.sendRollDiceIntentDebug()
                        }

                        actionButton(
                            "Submit Discard",
                            requiresCurrentPlayer: false,
                            isEnabled: viewModel.canSendSubmitDiscardIntentDebug
                        ) {
                            viewModel.sendSubmitDiscardIntentDebug()
                        }

                        actionButton(
                            "Move Robber (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendMoveRobberIntentDebug
                        ) {
                            viewModel.sendMoveRobberIntentDebug()
                        }

                        ForEach(viewModel.stealVictimOptions, id: \.self) { victim in
                            actionButton(
                                "Steal From \(victim) (Current Player)",
                                requiresCurrentPlayer: true,
                                isEnabled: true
                            ) {
                                viewModel.sendSelectStealVictimIntentDebug(victimPlayer: victim)
                            }
                        }

                        actionButton(
                            "Build Road (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendBuildRoadIntentDebug
                        ) {
                            viewModel.sendBuildRoadIntentDebug()
                        }

                        actionButton(
                            "Build Settlement (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendBuildSettlementIntentDebug
                        ) {
                            viewModel.sendBuildSettlementIntentDebug()
                        }

                        actionButton(
                            "Build City (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendBuildCityIntentDebug
                        ) {
                            viewModel.sendBuildCityIntentDebug()
                        }

                        actionButton(
                            "Propose Trade (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendProposeTradeIntentDebug
                        ) {
                            viewModel.sendProposeTradeIntentDebug()
                        }

                        actionButton(
                            "Accept Trade",
                            requiresCurrentPlayer: false,
                            isEnabled: viewModel.canSendAcceptTradeIntentDebug
                        ) {
                            viewModel.sendAcceptTradeIntentDebug()
                        }

                        actionButton(
                            "Execute Trade Accept (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendExecuteTradeIntentDebug
                        ) {
                            viewModel.sendExecuteTradeIntentDebug()
                        }

                        actionButton(
                            "Maritime Trade (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendMaritimeTradeIntentDebug
                        ) {
                            viewModel.sendMaritimeTradeIntentDebug()
                        }

                        actionButton(
                            "Buy Dev Card (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendBuyDevCardIntentDebug
                        ) {
                            viewModel.sendBuyDevCardIntentDebug()
                        }

                        actionButton(
                            "Play Knight (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendPlayKnightIntentDebug
                        ) {
                            viewModel.sendPlayKnightIntentDebug()
                        }

                        actionButton(
                            "Play Monopoly (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendPlayMonopolyIntentDebug
                        ) {
                            viewModel.sendPlayMonopolyIntentDebug()
                        }

                        actionButton(
                            "Play Year of Plenty (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendPlayYearOfPlentyIntentDebug
                        ) {
                            viewModel.sendPlayYearOfPlentyIntentDebug()
                        }

                        actionButton(
                            "Play Road Building (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendPlayRoadBuildingIntentDebug
                        ) {
                            viewModel.sendPlayRoadBuildingIntentDebug()
                        }

                        actionButton(
                            "Reveal VP (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendRevealVictoryPointIntentDebug
                        ) {
                            viewModel.sendRevealVictoryPointIntentDebug()
                        }

                        actionButton(
                            "End Turn (Current Player)",
                            requiresCurrentPlayer: true,
                            isEnabled: viewModel.canSendEndTurnIntentDebug
                        ) {
                            viewModel.sendEndTurnIntentDebug()
                        }
                    }

                    actionButton(
                        "Clear Pending Joins",
                        requiresCurrentPlayer: false,
                        isEnabled: viewModel.canClearPendingJoins
                    ) {
                        viewModel.clearPendingJoins()
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Debug Log")
                        .font(.subheadline)
                    if viewModel.uiLog.isEmpty {
                        Text("No events yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(viewModel.uiLog.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(.caption2, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

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

    private func actionButton(
        _ title: String,
        requiresCurrentPlayer: Bool,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Button(title) {
                action()
            }
            .buttonStyle(.bordered)
            .disabled(!isEnabled)

            if !isEnabled {
                Text(viewModel.disabledReason(requiresCurrentPlayer: requiresCurrentPlayer, isEnabled: isEnabled))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
