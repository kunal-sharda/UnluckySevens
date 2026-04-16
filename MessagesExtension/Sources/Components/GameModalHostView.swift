import SwiftUI
import ULS_CoreGame

struct GameModalHostView: View {
    let mode: GameMode
    let setupInstruction: String?
    let boardCommitDraft: GameBoardCommitDraft?
    let discardPanel: GameDiscardPanelModel?
    let devCardPanel: GameDevCardPanelModel?
    let robberVictimOptions: [GameRobberVictimOption]
    let onDiscardAction: () -> Void
    let onApplySelectedTurnIntent: () -> Void
    let onDevCardAction: (GameDevCardActionKind) -> Void
    let onConfirmDevCardDraft: () -> Void
    let onResetDevCardDraft: () -> Void
    let onConfirmBoardCommit: () -> Void
    let onCancelBoardCommit: () -> Void
    let onSelectStealVictim: (String) -> Void

    var body: some View {
        if let copy = copy(for: mode) {
            VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                Label(copy.title, systemImage: copy.systemImage)
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.ink)

                bodyContent(for: mode, fallbackMessage: copy.message)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(GameTheme.compactPadding)
            .background(GameTheme.surface.opacity(0.92))
            .overlay(
                RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                    .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private func bodyContent(for mode: GameMode, fallbackMessage: String) -> some View {
        if let boardCommitDraft {
            boardCommitContent(boardCommitDraft)
        } else {
            legacyBodyContent(for: mode, fallbackMessage: fallbackMessage)
        }
    }

    @ViewBuilder
    private func boardCommitContent(_ draft: GameBoardCommitDraft) -> some View {
        Text(draft.message)
            .font(GameTheme.metaFont)
            .foregroundStyle(GameTheme.mutedInk)
            .fixedSize(horizontal: false, vertical: true)

        Text(draft.summaryText)
            .font(GameTheme.metaFont.weight(.semibold))
            .foregroundStyle(GameTheme.accent)
            .fixedSize(horizontal: false, vertical: true)

        HStack(spacing: GameTheme.inlineSpacing) {
            Button("Cancel") {
                onCancelBoardCommit()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.bordered)

            Button(draft.confirmTitle) {
                onConfirmBoardCommit()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private func legacyBodyContent(for mode: GameMode, fallbackMessage: String) -> some View {
        switch mode {
        case .discard:
            discardContent(fallbackMessage: fallbackMessage)
        case .playDevCard,
             .devCardKnightMove,
             .devCardKnightVictim,
             .devCardMonopoly,
             .devCardYearOfPlenty,
             .devCardRoadBuildingFirst,
             .devCardRoadBuildingSecond:
            devCardContent(fallbackMessage: fallbackMessage)
        case .robberVictim:
            robberVictimContent(fallbackMessage: fallbackMessage)
        default:
            Text(fallbackMessage)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func discardContent(fallbackMessage: String) -> some View {
        if let discardPanel {
            Text(discardMessage(for: discardPanel))
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)

            if let action = discardPanel.action {
                discardChipRow(for: action)

                Button(action: discardButtonAction(for: action)) {
                    Text(discardButtonTitle(for: action))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if !discardPanel.waitingPlayers.isEmpty {
                Text("Waiting on: \(discardPanel.waitingPlayers.joined(separator: ", "))")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
            }
        } else {
            Text(fallbackMessage)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func robberVictimContent(fallbackMessage: String) -> some View {
        Text(fallbackMessage)
            .font(GameTheme.metaFont)
            .foregroundStyle(GameTheme.mutedInk)
            .fixedSize(horizontal: false, vertical: true)

        if !robberVictimOptions.isEmpty {
            ForEach(robberVictimOptions) { option in
                Button {
                    onSelectStealVictim(option.playerID)
                } label: {
                    HStack {
                        Text(option.displayName)
                        Spacer()
                        Text("\(option.handCount) cards")
                            .font(GameTheme.metaFont)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    private func devCardContent(fallbackMessage: String) -> some View {
        if let devCardPanel {
            Text(devCardPanel.message)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)

            if !devCardPanel.timingNotes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(devCardPanel.timingNotes.enumerated()), id: \.offset) { _, note in
                        Text(note)
                            .font(GameTheme.metaFont)
                            .foregroundStyle(GameTheme.mutedInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if !devCardPanel.playableCounts.isEmpty {
                devCardCountSection(title: "Playable", counts: devCardPanel.playableCounts)
            }

            if !devCardPanel.heldCounts.isEmpty {
                devCardCountSection(title: "Held", counts: devCardPanel.heldCounts)
            }

            if !devCardPanel.newCounts.isEmpty {
                devCardCountSection(title: "Held This Turn", counts: devCardPanel.newCounts)
            }

            if let draftSummary = devCardPanel.draftSummary {
                Text(draftSummary)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GameTheme.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !devCardPanel.playActions.isEmpty {
                VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                    Text("Play Or Reveal")
                        .font(GameTheme.metaFont.weight(.semibold))
                        .foregroundStyle(GameTheme.ink)

                    ForEach(devCardPanel.playActions) { action in
                        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                            Label(action.title, systemImage: action.systemImage)
                                .font(GameTheme.metaFont.weight(.semibold))
                                .foregroundStyle(GameTheme.ink)

                            Text(action.detail)
                                .font(GameTheme.metaFont)
                                .foregroundStyle(GameTheme.mutedInk)
                                .fixedSize(horizontal: false, vertical: true)

                            Button {
                                onDevCardAction(action.kind)
                            } label: {
                                Label(action.title, systemImage: action.systemImage)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.top, 4)
                    }
                }
            }

            if let confirmTitle = devCardPanel.confirmTitle {
                Button(confirmTitle) {
                    onConfirmDevCardDraft()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .disabled(!devCardPanel.canConfirm)
            }

            if devCardPanel.showsBackButton {
                Button("Back To Cards") {
                    onResetDevCardDraft()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
            }
        } else {
            Text(fallbackMessage)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func discardChipRow(for action: GameDiscardPanelModel.Action) -> some View {
        let chips = discardChips(for: action)
        if chips.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: GameTheme.chipSpacing) {
                    ForEach(chips) { chip in
                        chipView(chip)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func devCardCountSection(title: String, counts: [GameDevCardCount]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(GameTheme.metaFont.weight(.semibold))
                .foregroundStyle(GameTheme.ink)

            ForEach(counts) { count in
                HStack {
                    Text(count.title)
                        .foregroundStyle(GameTheme.ink)
                    Spacer()
                    Text("\(count.count)")
                        .font(GameTheme.metaFont)
                        .foregroundStyle(GameTheme.mutedInk)
                }
            }
        }
    }

    private func chipView(_ chip: GameHandChip) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(chip.shortLabel)
                .font(GameTheme.chipFont)
                .foregroundStyle(GameTheme.ink)
            Text("\(chip.count)")
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(chipBackground(for: chip))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.smallRadius))
    }

    private func discardMessage(for panel: GameDiscardPanelModel) -> String {
        switch panel.action {
        case let .publishSuggestedDiscard(requiredCount, _):
            return "Discard \(requiredCount) cards to continue the forced robber flow. Because you're the current player, this publishes the next canonical state immediately."
        case let .sendSuggestedDiscard(requiredCount, _):
            return "Discard \(requiredCount) cards to continue the forced robber flow. This sends your discard intent so the current player can incorporate it."
        case let .applySelectedDiscard(playerDisplay, _):
            return "Apply the selected discard intent from \(playerDisplay) to advance the forced robber flow."
        case .none:
            if panel.waitingPlayers.isEmpty {
                return "Discard resolution is blocking turn progress."
            }
            return "Discard resolution is blocking turn progress until the remaining players respond."
        }
    }

    private func discardButtonTitle(for action: GameDiscardPanelModel.Action) -> String {
        switch action {
        case .publishSuggestedDiscard:
            return "Publish Discard"
        case .sendSuggestedDiscard:
            return "Send Discard"
        case .applySelectedDiscard:
            return "Apply Selected Discard"
        }
    }

    private func discardButtonAction(for action: GameDiscardPanelModel.Action) -> () -> Void {
        switch action {
        case .publishSuggestedDiscard, .sendSuggestedDiscard:
            return onDiscardAction
        case .applySelectedDiscard:
            return onApplySelectedTurnIntent
        }
    }

    private func discardChips(for action: GameDiscardPanelModel.Action) -> [GameHandChip] {
        switch action {
        case let .publishSuggestedDiscard(_, suggested),
             let .sendSuggestedDiscard(_, suggested),
             let .applySelectedDiscard(_, suggested):
            return suggested
        }
    }

    private func chipBackground(for chip: GameHandChip) -> Color {
        switch chip.resource {
        case .wood:
            return GameTheme.wood.opacity(0.28)
        case .brick:
            return GameTheme.brick.opacity(0.24)
        case .sheep:
            return GameTheme.sheep.opacity(0.24)
        case .wheat:
            return GameTheme.wheat.opacity(0.26)
        case .ore:
            return GameTheme.ore.opacity(0.22)
        case .desert:
            return GameTheme.surfaceRaised.opacity(0.4)
        }
    }

    private func copy(for mode: GameMode) -> (title: String, message: String, systemImage: String)? {
        switch mode {
        case .setup:
            let message = setupInstruction ?? "Tap the highlighted placement to continue setup."
            return ("Setup Placement", message, "house.lodge.fill")
        case .buildRoad:
            return ("Build Road", "Select a legal road location on the board.", "road.lanes")
        case .buildSettlement:
            return ("Build Settlement", "Select a legal settlement location on the board.", "house.fill")
        case .buildCity:
            return ("Build City", "Select one of your highlighted settlements to upgrade.", "building.2.fill")
        case .robberMove:
            return ("Move The Robber", "Tap a highlighted tile to move the robber. If a victim is available, the next step will ask you to pick who to steal from.", "figure.fall")
        case .robberVictim:
            return ("Steal A Card", "Choose one eligible victim. Only players adjacent to the robber's new tile and holding cards are shown.", "person.crop.circle.badge.questionmark")
        case .playDevCard:
            return ("Dev Cards", "Choose a development card to play, then complete the required board or bank selections.", "sparkles.rectangle.stack.fill")
        case .devCardKnightMove:
            return ("Play Knight", "Choose the robber tile on the board.", "shield.lefthalf.filled")
        case .devCardKnightVictim:
            return ("Knight Victim", "Choose which highlighted player to steal from.", "person.crop.circle.badge.questionmark")
        case .devCardMonopoly:
            return ("Play Monopoly", "Choose a resource from the bank strip, then confirm.", "shippingbox.fill")
        case .devCardYearOfPlenty:
            return ("Year Of Plenty", "Choose two resources from the bank strip, then confirm.", "leaf.fill")
        case .devCardRoadBuildingFirst:
            return ("Road Building", "Choose the first road on the board.", "road.lanes")
        case .devCardRoadBuildingSecond:
            return ("Road Building", "Choose the second connected road on the board.", "road.lanes")
        case .discard:
            return ("Discard Required", "Discard resolution is blocking turn progress.", "exclamationmark.triangle.fill")
        default:
            return nil
        }
    }
}
