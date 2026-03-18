import SwiftUI
import ULS_CoreGame

struct GameModalHostView: View {
    let mode: GameMode
    let setupInstruction: String?
    let discardPanel: GameDiscardPanelModel?
    let tradePanel: GameTradePanelModel?
    let robberVictimOptions: [GameRobberVictimOption]
    let onDiscardAction: () -> Void
    let onTradeAction: (GameTradeActionKind) -> Void
    let onApplySelectedTurnIntent: () -> Void
    let onExecuteTrade: (String) -> Void
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
        switch mode {
        case .discard:
            discardContent(fallbackMessage: fallbackMessage)
        case .trade:
            tradeContent(fallbackMessage: fallbackMessage)
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
    private func tradeContent(fallbackMessage: String) -> some View {
        if let tradePanel {
            Text(tradePanel.message)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)

            if let activeOffer = tradePanel.activeOffer {
                tradeOfferSection(activeOffer)
            }

            if !tradePanel.acceptedPlayers.isEmpty {
                Text("Accepted: \(tradePanel.acceptedPlayers.joined(separator: ", "))")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
            }

            ForEach(tradePanel.actions) { action in
                VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                    Text(action.detail)
                        .font(GameTheme.metaFont)
                        .foregroundStyle(GameTheme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)

                    tradeResourceSection(
                        label: action.giveLabel,
                        chips: action.give
                    )
                    tradeResourceSection(
                        label: action.receiveLabel,
                        chips: action.receive
                    )

                    Button {
                        onTradeAction(action.kind)
                    } label: {
                        Text(action.title)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 4)
            }

            if !tradePanel.executeOptions.isEmpty {
                VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                    Text("Execute With")
                        .font(GameTheme.metaFont.weight(.semibold))
                        .foregroundStyle(GameTheme.ink)

                    ForEach(tradePanel.executeOptions) { option in
                        Button {
                            onExecuteTrade(option.playerID)
                        } label: {
                            HStack {
                                Text(option.displayName)
                                Spacer()
                                Text("Execute")
                                    .font(GameTheme.metaFont)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                    }
                }
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
    private func tradeOfferSection(_ offer: GameTradeOfferSummary) -> some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            Text("Offer")
                .font(GameTheme.metaFont.weight(.semibold))
                .foregroundStyle(GameTheme.ink)

            tradeResourceSection(label: offer.giveLabel, chips: offer.give)
            tradeResourceSection(label: offer.receiveLabel, chips: offer.receive)
        }
    }

    @ViewBuilder
    private func tradeResourceSection(label: String, chips: [GameHandChip]) -> some View {
        if !chips.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GameTheme.ink)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: GameTheme.chipSpacing) {
                        ForEach(chips) { chip in
                            chipView(chip)
                        }
                    }
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
        case .robberMove:
            return ("Move The Robber", "Tap a highlighted tile to move the robber. If a victim is available, the next step will ask you to pick who to steal from.", "figure.fall")
        case .robberVictim:
            return ("Steal A Card", "Choose one eligible victim. Only players adjacent to the robber's new tile and holding cards are shown.", "person.crop.circle.badge.questionmark")
        case .trade:
            return ("Trade", "Player and maritime trade actions now flow through compact suggested actions instead of the debug controls.", "arrow.left.arrow.right.circle.fill")
        case .playDevCard:
            return ("Dev Card Mode", "Card-specific flows stay deferred for now. This host is where the phase-12 dev-card sheet will land.", "sparkles.rectangle.stack.fill")
        case .discard:
            return ("Discard Required", "Discard resolution is blocking turn progress.", "exclamationmark.triangle.fill")
        default:
            return nil
        }
    }
}
