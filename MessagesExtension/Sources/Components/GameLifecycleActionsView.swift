import SwiftUI

/// One production surface for current-game actions and their confirmations.
struct GameLifecycleActionsView: View {
    let availability: GameLifecycleActionPresentation.Availability
    let unavailableMessage: String?
    let shouldOfferDrawBeforeHostEnd: Bool
    let onAction: (GameLifecycleActionPresentation.Action) -> Void
    let onClose: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var presentation = GameLifecycleActionPresentation()

    var body: some View {
        ViewThatFits(in: .vertical) {
            VStack(alignment: .leading, spacing: 12) {
                header
                screenContent
            }
            .padding(16)
            .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                header
                ScrollView {
                    screenContent
                        .padding(.bottom, 4)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .padding(16)
        }
        .frame(maxWidth: 326)
        .background(GameTheme.felt.opacity(0.98), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.45), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.30), radius: 8, y: 3)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(presentation.screen == .actions ? "uls.games.lifecycleActions" : "uls.games.lifecycleConfirmation")
    }

    @ViewBuilder
    private var screenContent: some View {
        switch presentation.screen {
        case .actions:
            actionList
        case .resign:
            resignConfirmation
        case .hostEnd:
            endGameConfirmation
        case .proposeDraw:
            drawProposal
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(GameTheme.titleFont)
                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
            .accessibilityLabel("Close game actions")
            .accessibilityIdentifier("uls.games.close")
        }
    }

    private var title: String {
        switch presentation.screen {
        case .actions: "Game actions"
        case .resign: "Resign?"
        case .hostEnd: "End this game?"
        case .proposeDraw: "Propose a draw?"
        }
    }

    private var actionList: some View {
        VStack(spacing: 0) {
            if let unavailableMessage {
                explanation(unavailableMessage)
            }
            ForEach(visibleActions, id: \.title) { item in
                actionRow(title: item.title, symbol: item.symbol, identifier: item.identifier) {
                    if let action = presentation.select(item.action, availability: availability) { onAction(action) }
                }
                if item.title != visibleActions.last?.title { separator }
            }
        }
    }

    private var visibleActions: [(title: String, symbol: String, identifier: String, action: GameLifecycleActionPresentation.Action)] {
        let actions: [(String, String, String, GameLifecycleActionPresentation.Action)] = [
            ("Resend Game Update", "arrow.clockwise", "resendUpdate", .resendUpdate),
            ("Declare Victory", "trophy", "claimVictory", .claimVictory),
            ("Agree to Draw", "hand.thumbsup", "agreeDraw", .agreeDraw),
            ("Decline Draw", "hand.thumbsdown", "declineDraw", .declineDraw),
            ("Propose Draw", "hand.raised", "proposeDraw", .proposeDraw),
            ("Resign", "figure.walk.departure", "resign", .resign),
            ("End Game", "xmark.octagon", "endGame", .hostEnd),
        ]
        return actions.filter { availability.allows($0.3) }
    }

    private var resignConfirmation: some View {
        VStack(alignment: .leading, spacing: 18) {
            explanation("You will leave active play. Your pieces stay on the board, and the remaining players continue.")

            confirmationActions { resignButtons }
        }
    }

    private var endGameConfirmation: some View {
        VStack(alignment: .leading, spacing: 18) {
            explanation(shouldOfferDrawBeforeHostEnd
                ? "A draw gives every active player a say. Ending the game as host finishes it immediately, without a winner."
                : "Ending is unilateral. Final scores remain visible, but no winner is declared.")

            VStack(alignment: .leading, spacing: 10) {
                if shouldOfferDrawBeforeHostEnd && availability.allows(.proposeDraw) {
                    compactButton("Propose Draw", emphasis: .primary, identifier: "proposeDraw") {
                        _ = presentation.select(.proposeDraw, availability: availability)
                    }
                }
                confirmationActions { endGameButtons }
            }
        }
    }

    private var drawProposal: some View {
        VStack(alignment: .leading, spacing: 18) {
            explanation("Ask everyone to finish this game as a draw. Every active player must agree; otherwise, play continues.")

            confirmationActions { drawProposalButtons }
        }
    }

    @ViewBuilder
    private var resignButtons: some View {
        compactButton("Keep Playing", emphasis: .primary, identifier: "keepPlaying") { presentation.cancel() }
        compactButton("Resign", emphasis: .destructive, identifier: "confirmResign", role: .destructive) { confirm() }
    }

    @ViewBuilder
    private var endGameButtons: some View {
        compactButton("Keep Playing", emphasis: .secondary, identifier: "keepPlaying") { presentation.cancel() }
        compactButton("End Game Anyway", emphasis: .destructive, identifier: "endAnyway", role: .destructive) { confirm() }
    }

    @ViewBuilder
    private var drawProposalButtons: some View {
        compactButton("Propose Draw", emphasis: .primary, identifier: "confirmProposeDraw") { confirm() }
        compactButton("Keep Playing", emphasis: .secondary, identifier: "keepPlaying") { presentation.cancel() }
    }

    private func confirm() {
        if let action = presentation.confirm(availability: availability) { onAction(action) }
    }

    private func confirmationActions<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 10))
            : AnyLayout(HStackLayout(spacing: 10))
        return layout { content() }
    }

    @ViewBuilder
    private func compactButton(
        _ title: String,
        emphasis: GameTabletopActionButtonStyle.Emphasis,
        identifier: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        if emphasis == .primary {
            Button(role: role, action: action) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .buttonStyle(GameTabletopActionButtonStyle(emphasis: .primary, solidBackground: true))
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("uls.games.\(identifier)")
        } else {
            Button(role: role, action: action) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(emphasis == .destructive ? Color(red: 1, green: 0.58, blue: 0.52) : GamePhysicalTurnPalette.primaryText)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("uls.games.\(identifier)")
        }
    }

    private func explanation(_ text: String) -> some View {
        Text(text)
            .font(GameTheme.bodyFont)
            .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var separator: some View {
        Rectangle()
            .fill(GamePhysicalTurnPalette.nameTileEdge.opacity(0.72))
            .frame(height: 1)
            .padding(.leading, 40)
            .accessibilityHidden(true)
    }

    private func actionRow(
        title: String,
        symbol: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: symbol)
                    .font(.headline)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.headline)

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(GamePhysicalTurnPalette.primaryText)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(
            identifier == "resendUpdate" || identifier == "claimVictory"
                ? "uls.gameInfo.\(identifier)"
                : "uls.games.\(identifier)"
        )
    }
}
