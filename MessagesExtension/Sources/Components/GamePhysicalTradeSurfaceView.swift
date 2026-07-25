import SwiftUI
import ULS_CoreGame

/// Physical Props presentation for the existing production trade routes.
/// Draft ownership, legality, recipient semantics, and publication remain in `GameShellView`.
struct GamePhysicalTradeSurfaceView: View {
    private static let resources: [ResourceV1] = [.wood, .brick, .sheep, .wheat, .ore]

    let route: GameTradeOverlayRoute
    let panelModel: GameTradePanelModel
    let bankChips: [GameBankChip]
    let handChips: [GameHandChip]
    let recipientSummaries: [GameOpponentSummary]
    let tutorialTarget: GameTutorialTarget?
    @Binding var showsRecipients: Bool
    let recipientScrimTopInset: CGFloat
    let onClose: () -> Void
    let onChoosePlayerTrade: () -> Void
    let onChooseMaritimeTrade: () -> Void
    let onReplaceOffer: () -> Void
    let onStartCounterDraft: () -> Void
    let onSendDraft: () -> Void
    let onBack: () -> Void
    let onAddGiveResource: (ResourceV1) -> Void
    let onRemoveGiveResource: (ResourceV1) -> Void
    let onAddWantResource: (ResourceV1) -> Void
    let onRemoveWantResource: (ResourceV1) -> Void
    let onToggleRecipient: (String) -> Void
    let onAcceptOffer: () -> Void
    let onDeclineOffer: () -> Void
    let onSendMaritimeTrade: (GameTradeMaritimeOption) -> Void

    @State private var selectedMaritimeOptionID: String?

    var body: some View {
        Group {
            switch route {
            case .chooser:
                chooser
            case let .playerDraft(draft):
                playerTrade(draft)
            case .maritime:
                maritime
            case .liveOffer:
                liveOffer
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: tutorialTarget) {
            showsRecipients = tutorialTarget == .tradeRecipients
        }
        .task(id: panelModel.maritimeOptions.map(\.id).joined(separator: "|")) {
            if let selectedMaritimeOptionID,
               panelModel.maritimeOptions.contains(where: { $0.id == selectedMaritimeOptionID }) {
                return
            }
            selectedMaritimeOptionID = panelModel.maritimeOptions.first?.id
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.physicalTrade.surface")
    }

    private var chooser: some View {
        HStack(spacing: 24) {
            tradeChoice(
                title: "Player Trade",
                systemImage: "person.2.fill",
                action: onChoosePlayerTrade
            )

            tradeChoice(
                title: "Bank or Port",
                assetName: "merchant_ship_colored",
                isDisabled: panelModel.maritimeOptions.isEmpty,
                action: onChooseMaritimeTrade
            )
        }
    }

    private func playerTrade(_ draft: GameTradeDraft) -> some View {
        ZStack {
            playerComposerPanel(draft)
                .padding(.horizontal, 12)

            if showsRecipients {
                GamePhysicalTurnPalette.focusVeil
                    .padding(.top, recipientScrimTopInset)
                    .accessibilityHidden(true)

                recipientPanel(draft)
                    .padding(.horizontal, 20)
            }
        }
        .accessibilityIdentifier("uls.physicalTrade.playerPresentation")
    }

    private func playerComposerPanel(_ draft: GameTradeDraft) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Text(draft.isCounter ? "Counter Trade" : "Player Trade")
                    .font(.headline)
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                    .frame(maxWidth: .infinity)

                HStack {
                    Spacer(minLength: 0)
                    Button("Close trade", systemImage: "xmark", action: onClose)
                        .labelStyle(.iconOnly)
                        .font(.headline)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        .gameTutorialTarget(.tradeClose)
                        .accessibilityIdentifier("uls.physicalTrade.close")
                }
            }

            resourceRow(
                title: "Give",
                identifier: "give",
                chips: handChips,
                selectedHand: draft.give,
                target: .tradeGive,
                onAdd: onAddGiveResource,
                onRemove: onRemoveGiveResource
            )

            Divider()
                .overlay(GamePhysicalTurnPalette.primaryText.opacity(0.18))

            resourceRow(
                title: "Get",
                identifier: "get",
                chips: bankChips.map { GameHandChip(resource: $0.resource, count: $0.count) },
                selectedHand: draft.receive,
                target: .tradeWant,
                onAdd: onAddWantResource,
                onRemove: onRemoveWantResource
            )

            Button {
                showsRecipients = true
            } label: {
                Label(
                    recipientButtonTitle(draft),
                    systemImage: "person.2.fill"
                )
                .font(.headline)
                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    GamePhysicalTurnPalette.nameTileFill,
                    in: RoundedRectangle(cornerRadius: 9)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(GamePhysicalTurnPalette.selectedKeyline, lineWidth: 1.5)
                }
                .frame(width: 274)
            }
            .buttonStyle(.plain)
            .disabled(handTotal(draft.give) == 0 || handTotal(draft.receive) == 0)
            .opacity(handTotal(draft.give) == 0 || handTotal(draft.receive) == 0 ? 0.42 : 1)
            .accessibilityIdentifier("uls.physicalTrade.chooseRecipients")
        }
        .padding(14)
        .frame(maxWidth: 346)
        .background(
            GameTheme.felt.opacity(0.98),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.74), lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.30), radius: 8, y: 3)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.physicalTrade.composerPanel")
    }

    private func resourceRow(
        title: String,
        identifier: String,
        chips: [GameHandChip],
        selectedHand: ResourceHandV1,
        target: GameTutorialTarget,
        onAdd: @escaping (ResourceV1) -> Void,
        onRemove: @escaping (ResourceV1) -> Void
    ) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                    .frame(maxWidth: .infinity)

                HStack {
                    Spacer(minLength: 0)
                    Text(selectedSummary(selectedHand))
                        .font(.subheadline)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .lineLimit(1)
                }
            }
            .frame(width: 274)

            HStack(spacing: 6) {
                ForEach(Self.resources, id: \.self) { resource in
                    let chip = chips.first(where: { $0.resource == resource })
                        ?? GameHandChip(resource: resource, count: 0)
                    resourceCardControl(
                        chip: chip,
                        selectedHand: selectedHand,
                        stageTitle: title,
                        identifier: identifier,
                        onAdd: onAdd,
                        onRemove: onRemove
                    )
                }
            }
            .frame(width: 274)
        }
        .frame(width: 274)
        .gameTutorialTarget(target)
        .accessibilityElement(children: .contain)
    }

    private func resourceCardControl(
        chip: GameHandChip,
        selectedHand: ResourceHandV1,
        stageTitle: String,
        identifier: String,
        onAdd: @escaping (ResourceV1) -> Void,
        onRemove: @escaping (ResourceV1) -> Void
    ) -> some View {
        let selected = count(chip.resource, in: selectedHand)
        return VStack(spacing: 2) {
            Button {
                onAdd(chip.resource)
            } label: {
                GameTabletopPortraitCardView(
                    face: .resource(chip.resource),
                    size: GamePhysicalTurnLayout.handCardSize,
                    count: nil,
                    isFaded: chip.count == 0,
                    stackDepth: 1
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            selected > 0
                                ? GamePhysicalTurnPalette.selectedKeyline
                                : Color.clear,
                            lineWidth: 2.5
                        )
                }
                .overlay(alignment: .topTrailing) {
                    if selected > 0 {
                        countBadge(selected, inverse: false)
                            .offset(x: 5, y: -5)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    countBadge(chip.count, inverse: true)
                        .offset(x: -4, y: 4)
                }
                .frame(width: 50, height: 60)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(chip.count == 0 || selected >= chip.count)
            .accessibilityLabel("Add \(chip.shortLabel) to \(stageTitle)")
            .accessibilityValue("\(selected) selected, \(chip.count) available")
            .accessibilityIdentifier("uls.physicalTrade.\(identifier).\(resourceID(chip.resource)).add")

            if selected > 0 {
                Button {
                    onRemove(chip.resource)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            GamePhysicalTurnPalette.primaryText,
                            GamePhysicalTurnPalette.nameTileFill
                        )
                        .frame(width: 28, height: 28)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(chip.shortLabel) from \(stageTitle)")
                .accessibilityValue("\(selected) selected")
                .accessibilityIdentifier("uls.physicalTrade.\(identifier).\(resourceID(chip.resource)).remove")
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: 50, height: 106)
    }

    private func recipientPanel(_ draft: GameTradeDraft) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Text("Choose Players")
                    .font(.headline)
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                    .frame(maxWidth: .infinity)

                HStack {
                    Button("Edit", systemImage: "chevron.left") {
                        showsRecipients = false
                    }
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Edit trade cards")
                    .accessibilityIdentifier("uls.physicalTrade.editCards")

                    Spacer(minLength: 0)

                    Button("Close trade", systemImage: "xmark", action: onClose)
                        .labelStyle(.iconOnly)
                        .font(.headline)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        .gameTutorialTarget(.tradeClose)
                        .accessibilityIdentifier("uls.physicalTrade.recipientClose")
                }
            }

            VStack(spacing: 8) {
                if draft.isCounter {
                    if let summary = recipientSummaries.first(where: { $0.id == draft.recipients.first }) {
                        recipientRow(summary, isSelected: true, isFixed: true)
                    }
                } else {
                    ForEach(Array(recipientSummaries.prefix(3))) { summary in
                        recipientRow(
                            summary,
                            isSelected: draft.recipients.contains(summary.id),
                            isFixed: false
                        )
                    }
                }
            }

            HStack(spacing: 10) {
                Button(action: onBack) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            GamePhysicalTurnPalette.nameTileFill.opacity(0.72),
                            in: RoundedRectangle(cornerRadius: 9)
                        )
                        .contentShape(Rectangle())
                }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Cancel")
                    .accessibilityIdentifier("uls.physicalTrade.recipientCancel")

                Button(action: onSendDraft) {
                    Text(primaryDraftButtonTitle(draft))
                        .font(.headline)
                        .foregroundStyle(GamePhysicalTurnPalette.cardCountInk)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            GamePhysicalTurnPalette.selectedKeyline,
                            in: RoundedRectangle(cornerRadius: 9)
                        )
                        .contentShape(Rectangle())
                }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(primaryDraftButtonTitle(draft))
                    .disabled(!canSend(draft))
                    .opacity(canSend(draft) ? 1 : 0.42)
                    .accessibilityIdentifier("uls.physicalTrade.sendOffer")
            }
        }
        .padding(14)
        .frame(maxWidth: 330)
        .background(
            GameTheme.felt.opacity(0.99),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(GamePhysicalTurnPalette.selectedKeyline, lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.42), radius: 8, y: 3)
        .gameTutorialTarget(.tradeRecipients)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.physicalTrade.recipientOverlay")
    }

    private func recipientRow(
        _ summary: GameOpponentSummary,
        isSelected: Bool,
        isFixed: Bool
    ) -> some View {
        Button {
            guard !isFixed else { return }
            onToggleRecipient(summary.id)
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(playerColor(summary))
                    Image(systemName: "person.fill")
                        .font(.headline)
                        .foregroundStyle(Color.white.opacity(0.92))
                }
                .frame(width: 38, height: 38)
                .overlay {
                    Circle()
                        .stroke(
                            isSelected
                                ? GamePhysicalTurnPalette.selectedKeyline
                                : GamePhysicalTurnPalette.primaryText.opacity(0.38),
                            lineWidth: isSelected ? 3 : 1
                        )
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.displayName)
                        .font(.headline)
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                        .lineLimit(1)
                    Text("\(summary.victoryPoints) VP · \(summary.handCount) cards")
                        .font(.subheadline)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(
                        isSelected
                            ? GamePhysicalTurnPalette.selectedKeyline
                            : GamePhysicalTurnPalette.tertiaryText
                    )
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                isSelected
                    ? playerColor(summary).opacity(0.24)
                    : GamePhysicalTurnPalette.nameTileFill.opacity(0.36),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected
                            ? GamePhysicalTurnPalette.selectedKeyline
                            : GamePhysicalTurnPalette.primaryText.opacity(0.18),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(summary.displayName)
        .accessibilityValue(
            "\(summary.victoryPoints) victory points, \(summary.handCount) cards, \(isSelected ? "selected" : "not selected")"
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("uls.physicalTrade.recipient.\(summary.id)")
    }

    private var maritime: some View {
        VStack(spacing: 10) {
            ZStack {
                        Text("Bank or Port Trade")
                    .font(.headline)
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText)

                HStack {
                    Button("Back", systemImage: "chevron.left", action: onBack)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("uls.physicalTrade.maritimeBack")

                    Spacer(minLength: 0)

                    Button("Close trade", systemImage: "xmark", action: onClose)
                        .labelStyle(.iconOnly)
                        .font(.headline)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        .gameTutorialTarget(.tradeClose)
                        .accessibilityIdentifier("uls.physicalTrade.maritimeClose")
                }
            }

            if panelModel.maritimeOptions.isEmpty {
                Text("No Bank or Port trades available")
                    .font(.body)
                    .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 88)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                            ForEach(panelModel.maritimeOptions) { option in
                                maritimeOption(option)
                                    .containerRelativeFrame(.horizontal)
                                    .id(option.id)
                            }
                    }
                    .scrollTargetLayout()
                }
                .frame(height: 138)
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $selectedMaritimeOptionID)
                .scrollBounceBehavior(.basedOnSize)
                .accessibilityIdentifier("uls.physicalTrade.maritimePager")

                if panelModel.maritimeOptions.count > 1 {
                    HStack(spacing: 16) {
                        maritimePageButton(
                            title: "Previous exchange",
                            systemImage: "chevron.left",
                            isEnabled: canPageMaritimeBackward,
                            offset: -1
                        )

                        Text("\(selectedMaritimeOptionNumber) of \(panelModel.maritimeOptions.count)")
                            .font(.caption)
                            .bold()
                            .monospacedDigit()
                            .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                            .frame(minWidth: 48)
                            .accessibilityLabel(
                                "Exchange \(selectedMaritimeOptionNumber) of \(panelModel.maritimeOptions.count)"
                            )
                            .accessibilityIdentifier("uls.physicalTrade.maritimePosition")

                        maritimePageButton(
                            title: "Next exchange",
                            systemImage: "chevron.right",
                            isEnabled: canPageMaritimeForward,
                            offset: 1
                        )
                    }
                }
            }

            if let selectedMaritimeOption {
                confirmMaritimeButton(selectedMaritimeOption)
            }
        }
        .padding(14)
        .frame(maxWidth: 346)
        .background(
            GameTheme.felt.opacity(0.98),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.74), lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.30), radius: 8, y: 3)
        .gameTutorialTarget(.maritimeOptions)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.physicalTrade.maritimePanel")
        .padding(.horizontal, 12)
    }

    private func maritimeOption(_ option: GameTradeMaritimeOption) -> some View {
        HStack(spacing: 12) {
            exchangeSide(option.give)

            Image(systemName: "arrow.right")
                .font(.title2)
                .bold()
                .foregroundStyle(GamePhysicalTurnPalette.selectedKeyline)
                .accessibilityHidden(true)

            exchangeSide(option.receive)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 126)
        .background(
            GamePhysicalTurnPalette.nameTileFill.opacity(0.44),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(GamePhysicalTurnPalette.selectedKeyline, lineWidth: 1.5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(maritimeAccessibilityLabel(option))
        .accessibilityIdentifier("uls.physicalTrade.maritimeOption.\(option.id)")
    }

    private var selectedMaritimeOption: GameTradeMaritimeOption? {
        if let selectedMaritimeOptionID,
           let option = panelModel.maritimeOptions.first(where: { $0.id == selectedMaritimeOptionID }) {
            return option
        }
        return panelModel.maritimeOptions.first
    }

    private var selectedMaritimeOptionNumber: Int {
        guard let selectedMaritimeOptionIndex else {
            return panelModel.maritimeOptions.isEmpty ? 0 : 1
        }
        return selectedMaritimeOptionIndex + 1
    }

    private var selectedMaritimeOptionIndex: Int? {
        guard let selectedMaritimeOptionID else { return nil }
        return panelModel.maritimeOptions.firstIndex(where: {
            $0.id == selectedMaritimeOptionID
        })
    }

    private var canPageMaritimeBackward: Bool {
        (selectedMaritimeOptionIndex ?? 0) > 0
    }

    private var canPageMaritimeForward: Bool {
        (selectedMaritimeOptionIndex ?? 0) < panelModel.maritimeOptions.count - 1
    }

    private func maritimePageButton(
        title: String,
        systemImage: String,
        isEnabled: Bool,
        offset: Int
    ) -> some View {
        Button(title, systemImage: systemImage) {
            moveMaritimeSelection(by: offset)
        }
        .labelStyle(.iconOnly)
        .font(.headline)
        .foregroundStyle(GamePhysicalTurnPalette.selectedKeyline)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.28)
        .accessibilityIdentifier(
            offset < 0
                ? "uls.physicalTrade.previousMaritime"
                : "uls.physicalTrade.nextMaritime"
        )
    }

    private func moveMaritimeSelection(by offset: Int) {
        let currentIndex = selectedMaritimeOptionIndex ?? 0
        let nextIndex = currentIndex + offset
        guard panelModel.maritimeOptions.indices.contains(nextIndex) else { return }
        selectedMaritimeOptionID = panelModel.maritimeOptions[nextIndex].id
    }

    private func confirmMaritimeButton(_ option: GameTradeMaritimeOption) -> some View {
        Button {
            onSendMaritimeTrade(option)
        } label: {
            Label("Confirm Trade", systemImage: "checkmark")
                .font(.headline)
                .foregroundStyle(GamePhysicalTurnPalette.cardCountInk)
                .frame(width: 274)
                .frame(minHeight: 44)
                .background(
                    GamePhysicalTurnPalette.selectedKeyline,
                    in: RoundedRectangle(cornerRadius: 9)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Confirm Trade")
        .accessibilityValue(maritimeAccessibilityLabel(option))
        .accessibilityIdentifier("uls.physicalTrade.confirmMaritime")
    }

    private func exchangeSide(_ chips: [GameHandChip]) -> some View {
        VStack(spacing: 5) {
            resourceCards(chips, cardSize: GamePhysicalTurnLayout.handCardSize)
            Text(chipDescription(chips))
                .font(.subheadline)
                .bold()
                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var liveOffer: some View {
        if let offer = panelModel.activeOffer, let actions = panelModel.responderActions {
            GamePhysicalIncomingTradeView(
                offer: offer,
                actions: actions,
                onAccept: onAcceptOffer,
                onDecline: onDeclineOffer,
                onCounter: onStartCounterDraft
            )
        } else if let offer = panelModel.activeOffer {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(panelModel.roleTitle)
                        .font(.caption)
                        .bold()
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                    Text(offer.recipientsLabel)
                        .font(.caption)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                resourceCards(offer.give, cardSize: CGSize(width: 27, height: 34))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Give \(chipDescription(offer.give))")

                Image(systemName: "arrow.right")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(GamePhysicalTurnPalette.selectedKeyline)

                resourceCards(offer.receive, cardSize: CGSize(width: 27, height: 34))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Receive \(chipDescription(offer.receive))")

                if panelModel.canReplaceOffer {
                    Button("Replace Offer", systemImage: "arrow.triangle.2.circlepath", action: onReplaceOffer)
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                        .overlay {
                            Circle()
                                .stroke(GamePhysicalTurnPalette.selectedKeyline, lineWidth: 1.5)
                                .frame(width: 32, height: 32)
                        }
                        .accessibilityLabel("Replace Offer")
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("uls.physicalTrade.pending")
        } else {
            Text(panelModel.message)
                .font(.caption)
                .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
        }
    }

    private func tradeChoice(
        title: String,
        systemImage: String? = nil,
        assetName: String? = nil,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Group {
                    if let assetName {
                        Image(assetName)
                            .resizable()
                            .scaledToFit()
                    } else if let systemImage {
                        Image(systemName: systemImage)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(width: 38, height: 29)

                Text(title)
                    .font(.caption)
                    .bold()
                    .lineLimit(1)
            }
            .foregroundStyle(GamePhysicalTurnPalette.primaryText)
            .frame(width: 128)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.72), lineWidth: 1.25)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.42 : 1)
    }

    private func resourceCards(_ chips: [GameHandChip], cardSize: CGSize) -> some View {
        HStack(spacing: 4) {
            ForEach(chips) { chip in
                GameTabletopPortraitCardView(
                    face: .resource(chip.resource),
                    size: cardSize,
                    count: nil,
                    stackDepth: 1
                )
                .overlay(alignment: .bottomTrailing) {
                    countBadge(chip.count, inverse: true)
                        .offset(x: 4, y: 4)
                }
            }
        }
    }

    private func countBadge(_ count: Int, inverse: Bool) -> some View {
        Text(count, format: .number)
            .font(.caption)
            .bold()
            .monospacedDigit()
            .foregroundStyle(
                inverse
                    ? GamePhysicalTurnPalette.primaryText
                    : GamePhysicalTurnPalette.cardCountInk
            )
            .frame(width: 20, height: 20)
            .background(
                inverse
                    ? GamePhysicalTurnPalette.cardCountInk.opacity(0.92)
                    : GamePhysicalTurnPalette.selectedKeyline
            )
            .clipShape(Circle())
            .accessibilityHidden(true)
    }

    private func playerColor(_ summary: GameOpponentSummary) -> Color {
        Color(
            red: summary.playerTint.red,
            green: summary.playerTint.green,
            blue: summary.playerTint.blue
        )
    }

    private func canSend(_ draft: GameTradeDraft) -> Bool {
        handTotal(draft.give) > 0
            && handTotal(draft.receive) > 0
            && !draft.recipients.isEmpty
    }

    private func recipientButtonTitle(_ draft: GameTradeDraft) -> String {
        if draft.recipients.isEmpty {
            return "Choose Players"
        }
        return "Players · \(draft.recipients.count) selected"
    }

    private func primaryDraftButtonTitle(_ draft: GameTradeDraft) -> String {
        draft.isCounter ? "Send Counter" : "Send Offer"
    }

    private func count(_ resource: ResourceV1, in hand: ResourceHandV1) -> Int {
        switch resource {
        case .wood: hand.wood
        case .brick: hand.brick
        case .sheep: hand.sheep
        case .wheat: hand.wheat
        case .ore: hand.ore
        case .desert: 0
        }
    }

    private func handTotal(_ hand: ResourceHandV1) -> Int {
        hand.wood + hand.brick + hand.sheep + hand.wheat + hand.ore
    }

    private func selectedSummary(_ hand: ResourceHandV1) -> String {
        let total = handTotal(hand)
        return total == 0 ? "None selected" : "\(total) selected"
    }

    private func maritimeAccessibilityLabel(_ option: GameTradeMaritimeOption) -> String {
        "Give \(chipDescription(option.give)) for \(chipDescription(option.receive)), \(option.ratio) to 1 trade"
    }

    private func chipDescription(_ chips: [GameHandChip]) -> String {
        chips.map { "\($0.count) \($0.shortLabel)" }.joined(separator: ", ")
    }

    private func resourceID(_ resource: ResourceV1) -> String {
        switch resource {
        case .wood: "wood"
        case .brick: "brick"
        case .sheep: "sheep"
        case .wheat: "wheat"
        case .ore: "ore"
        case .desert: "desert"
        }
    }
}
