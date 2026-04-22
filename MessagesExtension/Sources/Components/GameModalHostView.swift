import SwiftUI
import ULS_CoreGame

struct GameModalHostView: View {
    let mode: GameMode
    let setupInstruction: String?
    let boardCommitDraft: GameBoardCommitDraft?
    let discardPanel: GameDiscardPanelModel?
    let devCardPanel: GameDevCardPanelModel?
    let robberVictimOptions: [GameRobberVictimOption]
    let discardSelectedHandCounts: [ResourceV1: Int]
    let onSelectDiscardResource: ((ResourceV1) -> Void)?
    let onRemoveDiscardResource: ((ResourceV1) -> Void)?
    let onDiscardAction: () -> Void
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
                let (requiredCount, availableHand): (Int, [GameHandChip]) = {
                    switch action {
                    case let .publishDiscard(required, hand):
                        return (required, hand)
                    }
                }()

                discardComposerSection(
                    requiredCount: requiredCount,
                    availableHand: availableHand
                )

                Button(action: onDiscardAction) {
                    Text(discardButtonTitle(for: action))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(discardSelectedCount != requiredCount)
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
    private func discardComposerSection(
        requiredCount: Int,
        availableHand: [GameHandChip]
    ) -> some View {
        let density = ResourceChipDensity.compact
        let remaining = max(requiredCount - discardSelectedCount, 0)

        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            Text("Selected discard (\(discardSelectedCount)/\(requiredCount))")
                .font(GameTheme.metaFont.weight(.semibold))
                .foregroundStyle(GameTheme.ink)

            if discardSelectedChips.isEmpty {
                Text("Nothing selected yet.")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
            } else {
                ResourceChipGridView(items: discardSelectedChips, density: density) { chip in
                    ResourceCountChipView(
                        resource: chip.resource,
                        label: chip.shortLabel,
                        count: chip.count,
                        isEnabled: true,
                        isSelected: true,
                        selectionBadge: nil,
                        detailBadge: "-",
                        density: density,
                        action: {
                            onRemoveDiscardResource?(chip.resource)
                        },
                        accessibilityLabel: "\(chip.shortLabel), remove one from discard selection"
                    )
                }
            }

            Text(remaining == 0 ? "Ready to submit." : "Select \(remaining) more card\(remaining == 1 ? "" : "s").")
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)

            VStack(alignment: .leading, spacing: 6) {
                Text("Your hand")
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GameTheme.ink)

                if availableHand.isEmpty {
                    Text("No resources in hand.")
                        .font(GameTheme.metaFont)
                        .foregroundStyle(GameTheme.mutedInk)
                } else {
                    ResourceChipGridView(items: availableHand, density: density) { chip in
                        discardAvailableChip(
                            chip,
                            requiredCount: requiredCount,
                            density: density
                        )
                    }
                }
            }
        }
    }

    private func discardAvailableChip(
        _ chip: GameHandChip,
        requiredCount: Int,
        density: ResourceChipDensity
    ) -> some View {
        let selected = discardSelectedHandCounts[chip.resource] ?? 0
        let canAdd = selected < chip.count && discardSelectedCount < requiredCount
        return ResourceCountChipView(
            resource: chip.resource,
            label: chip.shortLabel,
            count: chip.count,
            isEnabled: canAdd,
            isSelected: selected > 0,
            selectionBadge: selected > 0 ? String(selected) : nil,
            detailBadge: canAdd ? "+" : nil,
            density: density,
            action: canAdd ? {
                onSelectDiscardResource?(chip.resource)
            } : nil,
            accessibilityLabel: "\(chip.shortLabel), \(chip.count) in hand, \(selected) selected to discard"
        )
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
            if !devCardPanel.cards.isEmpty {
                devCardGrid(cards: devCardPanel.cards)
            }

            if mode != .playDevCard || devCardPanel.cards.isEmpty {
                Text(devCardPanel.message)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let draftSummary = devCardPanel.draftSummary {
                Text(draftSummary)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GameTheme.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if mode == .playDevCard, !devCardPanel.timingNotes.isEmpty {
                Text(devCardPanel.timingNotes[0])
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
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

    private func devCardGrid(cards: [GameDevCardTileModel]) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 0), spacing: GameTheme.inlineSpacing),
                GridItem(.flexible(minimum: 0), spacing: GameTheme.inlineSpacing),
            ],
            spacing: GameTheme.inlineSpacing
        ) {
            ForEach(cards) { card in
                devCardTile(card)
            }
        }
    }

    private func devCardTile(_ card: GameDevCardTileModel) -> some View {
        let tileBody = VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: card.kind.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(card.isEnabled ? GameTheme.accent : GameTheme.mutedInk)

                Spacer(minLength: 0)

                Text("\(card.count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(cardCountTint(for: card))
                    .clipShape(Capsule())
            }

            Text(card.kind.title)
                .font(GameTheme.metaFont.weight(.semibold))
                .foregroundStyle(GameTheme.ink)
                .lineLimit(2)

            Text(card.statusText)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(card.isEnabled ? GameTheme.accent : GameTheme.mutedInk)
                .lineLimit(2)

            Text(card.detailText)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 134, alignment: .topLeading)
        .padding(GameTheme.compactPadding)
        .background(devCardTileBackground(for: card))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(card.isSelected ? GameTheme.accent.opacity(0.48) : GameTheme.outline.opacity(0.14), lineWidth: card.isSelected ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
        .opacity(card.isEnabled || card.isSelected ? 1 : 0.88)

        return Group {
            if let action = card.actionKind {
                Button {
                    onDevCardAction(action)
                } label: {
                    tileBody
                }
                .buttonStyle(.plain)
            } else {
                tileBody
            }
        }
    }

    private func devCardTileBackground(for card: GameDevCardTileModel) -> Color {
        if card.isSelected {
            return GameTheme.accent.opacity(0.14)
        }
        return GameTheme.surface.opacity(0.92)
    }

    private func cardCountTint(for card: GameDevCardTileModel) -> Color {
        card.isEnabled ? GameTheme.accent : GameTheme.mutedInk.opacity(0.75)
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

    private func discardMessage(for panel: GameDiscardPanelModel) -> String {
        switch panel.action {
        case let .publishDiscard(requiredCount, _):
            return "Discard exactly \(requiredCount) cards to publish the next canonical discard state. Discarders resolve in roster order during this robber step."
        case .none:
            if panel.waitingPlayers.isEmpty {
                return "Discard resolution is blocking turn progress."
            }
            return "Discard resolution is blocking turn progress until the remaining players submit in order."
        }
    }

    private func discardButtonTitle(for action: GameDiscardPanelModel.Action) -> String {
        switch action {
        case .publishDiscard:
            return "Publish Discard"
        }
    }

    private var discardSelectedCount: Int {
        discardSelectedHandCounts.values.reduce(0, +)
    }

    private var discardSelectedChips: [GameHandChip] {
        ResourceV1.tradeableCases.compactMap { resource in
            let count = discardSelectedHandCounts[resource] ?? 0
            guard count > 0 else {
                return nil
            }
            return GameHandChip(resource: resource, count: count)
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

private extension ResourceV1 {
    static var tradeableCases: [ResourceV1] {
        [.wood, .brick, .sheep, .wheat, .ore]
    }
}
