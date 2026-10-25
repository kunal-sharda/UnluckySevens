#if DEBUG
import SwiftUI

/// Isolated visual checkpoint. Its controls change only local preview state.
struct GameLifecycleDesignPreviewView: View {
    enum Screen {
        case actions
        case resign
        case endGame
        case proposeDraw
        case drawVote
    }

    let isHost: Bool
    let onClose: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var screen: Screen

    init(initialScreen: Screen = .actions, isHost: Bool = true, onClose: @escaping () -> Void = {}) {
        self.isHost = isHost
        self.onClose = onClose
        _screen = State(initialValue: initialScreen)
    }

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
        .accessibilityIdentifier("uls.preview.lifecycle")
    }

    @ViewBuilder
    private var screenContent: some View {
        switch screen {
        case .actions:
            actionList
        case .resign:
            resignConfirmation
        case .endGame:
            endGameConfirmation
        case .proposeDraw:
            drawProposal
        case .drawVote:
            drawVote
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
            .accessibilityIdentifier("uls.preview.lifecycle.close")
        }
    }

    private var title: String {
        switch screen {
        case .actions: "Game actions"
        case .resign: "Resign?"
        case .endGame: "End this game?"
        case .proposeDraw: "Propose a draw?"
        case .drawVote: "Draw proposal"
        }
    }

    private var actionList: some View {
        VStack(spacing: 0) {
            actionRow(
                title: "Propose Draw",
                symbol: "hand.raised",
                identifier: "proposeDraw"
            ) { screen = .proposeDraw }

            separator

            actionRow(
                title: "Resign",
                symbol: "figure.walk.departure",
                identifier: "resign"
            ) { screen = .resign }

            if isHost {
                separator

                actionRow(
                    title: "End Game",
                    symbol: "xmark.octagon",
                    identifier: "endGame"
                ) { screen = .endGame }
            }
        }
    }

    private var resignConfirmation: some View {
        VStack(alignment: .leading, spacing: 18) {
            explanation("You will leave active play. Your pieces stay on the board, and the remaining players continue.")

            confirmationActions { resignButtons }
        }
    }

    private var endGameConfirmation: some View {
        VStack(alignment: .leading, spacing: 18) {
            explanation("A draw gives every active player a say. Ending the game as host finishes it immediately, without a winner.")

            VStack(alignment: .leading, spacing: 10) {
                compactButton("Propose Draw", emphasis: .primary, identifier: "proposeDrawInstead") {
                    screen = .proposeDraw
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

    private var drawVote: some View {
        VStack(alignment: .leading, spacing: 18) {
            explanation("Finish this game as a draw? Every active player must agree. If anyone declines, play continues.")

            confirmationActions { drawVoteButtons }
        }
    }

    @ViewBuilder
    private var resignButtons: some View {
        compactButton("Keep Playing", emphasis: .primary, identifier: "keepPlaying") { screen = .actions }
        compactButton("Resign", emphasis: .destructive, identifier: "confirmResign", role: .destructive) {
            screen = .actions
        }
    }

    @ViewBuilder
    private var endGameButtons: some View {
        compactButton("Keep Playing", emphasis: .secondary, identifier: "keepPlaying") { screen = .actions }
        compactButton("End Game Anyway", emphasis: .destructive, identifier: "confirmEnd", role: .destructive) {
            screen = .actions
        }
    }

    @ViewBuilder
    private var drawProposalButtons: some View {
        compactButton("Propose Draw", emphasis: .primary, identifier: "confirmProposeDraw") { screen = .drawVote }
        compactButton("Keep Playing", emphasis: .secondary, identifier: "keepPlaying") { screen = .actions }
    }

    @ViewBuilder
    private var drawVoteButtons: some View {
        compactButton("Agree to Draw", emphasis: .primary, identifier: "agreeDraw") { screen = .actions }
        compactButton("Keep Playing", emphasis: .secondary, identifier: "declineDraw") { screen = .actions }
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
            .accessibilityIdentifier("uls.preview.lifecycle.\(identifier)")
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
            .accessibilityIdentifier("uls.preview.lifecycle.\(identifier)")
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
        .accessibilityIdentifier("uls.preview.lifecycle.\(identifier)")
    }
}
#endif
