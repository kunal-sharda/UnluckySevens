import SwiftUI
import ULS_CoreGame

struct GameDiscardComposerView: View {
    static let minimumSurfaceHeight: CGFloat = 132

    let panel: GameDiscardPanelModel?
    let fallbackMessage: String
    let selectedCountsByResource: [ResourceV1: Int]
    let onAddResource: ((ResourceV1) -> Void)?
    let onRemoveResource: ((ResourceV1) -> Void)?
    let onSubmit: () -> Void

    private static let resources: [ResourceV1] = [.wood, .brick, .sheep, .wheat, .ore]

    var body: some View {
        Group {
            if let panel, let action = panel.action {
                switch action {
                case let .publishDiscard(requiredCount, availableHand):
                    activeComposer(requiredCount: requiredCount, availableHand: availableHand)
                }
            } else if let panel {
                waitingState(panel)
            } else {
                Text(fallbackMessage)
                    .font(.footnote)
                    .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.discard.surface")
    }

    private func activeComposer(
        requiredCount: Int,
        availableHand: [GameHandChip]
    ) -> some View {
        VStack(spacing: GameTheme.chipSpacing) {
            HStack(spacing: GameTheme.inlineSpacing) {
                Text(progressTitle(requiredCount: requiredCount))
                    .font(.footnote)
                    .bold()
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText)

                Spacer(minLength: 8)

                Text("\(selectedCount) / \(requiredCount)")
                    .font(.footnote)
                    .bold()
                    .monospacedDigit()
                    .foregroundStyle(
                        selectedCount == requiredCount
                            ? GamePhysicalTurnPalette.selectedKeyline
                            : GamePhysicalTurnPalette.secondaryText
                    )
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("uls.discard.progress")
            .accessibilityLabel("Discard selection")
            .accessibilityValue("\(selectedCount) of \(requiredCount) selected")

            HStack(alignment: .top, spacing: GameTheme.inlineSpacing) {
                HStack(spacing: GameTheme.chipSpacing) {
                    ForEach(availableHand) { chip in
                        handCard(chip, requiredCount: requiredCount)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Your hand. Choose exactly \(requiredCount) cards")

                Button(action: onSubmit) {
                    Text("Confirm")
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.82)
                }
                    .buttonStyle(GameTabletopActionButtonStyle(emphasis: .primary))
                    .frame(width: 96, height: 58, alignment: .center)
                    .opacity(selectedCount == requiredCount ? 1 : 0.46)
                    .disabled(selectedCount != requiredCount)
                    .accessibilityIdentifier("uls.discard.submit")
                    .accessibilityHint(
                        selectedCount == requiredCount
                            ? "Submits this discard"
                            : "Select exactly \(requiredCount) cards first"
                    )
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func handCard(_ chip: GameHandChip, requiredCount: Int) -> some View {
        let selected = selectedCountsByResource[chip.resource] ?? 0
        let canAdd = selected < chip.count && selectedCount < requiredCount

        return VStack(spacing: 4) {
            Button {
                onAddResource?(chip.resource)
            } label: {
                GamePhysicalResourceHandCardView(
                    chip: chip,
                    isFaded: !canAdd && selected == 0
                )
                .frame(width: 48, height: 58)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canAdd)
            .accessibilityIdentifier("uls.discard.hand.\(identifier(for: chip.resource))")
            .accessibilityLabel(chip.shortLabel)
            .accessibilityValue("\(chip.count) in hand, \(selected) selected")
            .accessibilityHint(canAdd ? "Adds one to the discard" : "No more can be selected")

            if selected > 0 {
                Button {
                    onRemoveResource?(chip.resource)
                } label: {
                    HStack(spacing: 4) {
                        Text("−")
                            .bold()

                        Text("\(selected)")
                            .bold()
                            .monospacedDigit()
                    }
                    .font(.caption)
                    .foregroundStyle(GamePhysicalTurnPalette.cardCountInk)
                    .frame(width: 36, height: 36)
                    .background(GamePhysicalTurnPalette.selectedKeyline, in: Circle())
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("uls.discard.selection.\(identifier(for: chip.resource))")
                .accessibilityLabel("Selected \(chip.shortLabel)")
                .accessibilityValue("\(selected) selected")
                .accessibilityHint("Returns one card to your hand")
            }
        }
        .frame(width: 48, height: 106, alignment: .top)
        .accessibilityElement(children: .contain)
    }

    private func waitingState(_ panel: GameDiscardPanelModel) -> some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            Image(systemName: "hourglass")
                .font(.title3)
                .bold()
                .foregroundStyle(GamePhysicalTurnPalette.selectedKeyline)
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(waitingTitle(panel))
                    .font(.headline)
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText)

                Text("The robber moves after each required player discards in order.")
                    .font(.footnote)
                    .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("uls.discard.waiting")
    }

    private var selectedCount: Int {
        selectedCountsByResource.values.reduce(0, +)
    }

    private func progressTitle(requiredCount: Int) -> String {
        selectedCount == requiredCount
            ? "Ready to discard"
            : "Choose exactly \(requiredCount) cards"
    }

    private func waitingTitle(_ panel: GameDiscardPanelModel) -> String {
        guard let nextPlayer = panel.waitingPlayers.first else {
            return "Waiting for discards"
        }
        return "Waiting for \(nextPlayer)"
    }

    private func resourceLabel(_ resource: ResourceV1) -> String {
        switch resource {
        case .wood: return "Wood"
        case .brick: return "Brick"
        case .sheep: return "Sheep"
        case .wheat: return "Wheat"
        case .ore: return "Ore"
        case .desert: return "Desert"
        }
    }

    private func identifier(for resource: ResourceV1) -> String {
        resourceLabel(resource).lowercased()
    }
}
