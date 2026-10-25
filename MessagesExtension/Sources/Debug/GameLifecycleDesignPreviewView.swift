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
    @State private var screen: Screen

    init(initialScreen: Screen = .actions, isHost: Bool = true, onClose: @escaping () -> Void = {}) {
        self.isHost = isHost
        self.onClose = onClose
        _screen = State(initialValue: initialScreen)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(18)
        .frame(maxWidth: 346)
        .background(GameTheme.felt.opacity(0.98), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.74), lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.30), radius: 8, y: 3)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.preview.lifecycle")
    }

    private var header: some View {
        HStack(spacing: 8) {
            if screen != .actions {
                Button {
                    screen = .actions
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                .accessibilityLabel("Back to game actions")
                .accessibilityIdentifier("uls.preview.lifecycle.back")
            }

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
                detail: "Let everyone agree to finish together.",
                symbol: "hand.raised",
                identifier: "proposeDraw"
            ) { screen = .proposeDraw }

            separator

            actionRow(
                title: "Resign",
                detail: "Leave active play. The others continue.",
                symbol: "figure.walk.departure",
                identifier: "resign"
            ) { screen = .resign }

            if isHost {
                separator

                actionRow(
                    title: "End Game",
                    detail: "As host, finish the game for everyone.",
                    symbol: "xmark.octagon",
                    identifier: "endGame"
                ) { screen = .endGame }
            }
        }
    }

    private var resignConfirmation: some View {
        VStack(alignment: .leading, spacing: 18) {
            explanation("You will leave active play. Your pieces stay on the board, and the remaining players continue.")

            VStack(spacing: 8) {
                Button("Keep Playing") { screen = .actions }
                    .buttonStyle(GameTabletopActionButtonStyle(emphasis: .primary, solidBackground: true))
                    .accessibilityIdentifier("uls.preview.lifecycle.keepPlaying")
                Button("Resign", role: .destructive) { screen = .actions }
                    .buttonStyle(GameTabletopActionButtonStyle(emphasis: .destructive, solidBackground: true))
                    .accessibilityIdentifier("uls.preview.lifecycle.confirmResign")
            }
        }
    }

    private var endGameConfirmation: some View {
        VStack(alignment: .leading, spacing: 18) {
            explanation("A draw gives every active player a say. Ending the game as host finishes it immediately, without a winner.")

            VStack(spacing: 8) {
                Button("Propose Draw") { screen = .proposeDraw }
                    .buttonStyle(GameTabletopActionButtonStyle(emphasis: .primary, solidBackground: true))
                    .accessibilityIdentifier("uls.preview.lifecycle.proposeDrawInstead")
                Button("Keep Playing") { screen = .actions }
                    .buttonStyle(GameTabletopActionButtonStyle(emphasis: .secondary, solidBackground: true))
                    .accessibilityIdentifier("uls.preview.lifecycle.keepPlaying")
                Button("End Game Anyway", role: .destructive) { screen = .actions }
                    .buttonStyle(GameTabletopActionButtonStyle(emphasis: .destructive, solidBackground: true))
                    .accessibilityIdentifier("uls.preview.lifecycle.confirmEnd")
            }
        }
    }

    private var drawProposal: some View {
        VStack(alignment: .leading, spacing: 18) {
            explanation("Ask everyone to finish this game as a draw. Every active player must agree; otherwise, play continues.")

            VStack(spacing: 8) {
                Button("Propose Draw") { screen = .drawVote }
                    .buttonStyle(GameTabletopActionButtonStyle(emphasis: .primary, solidBackground: true))
                    .accessibilityIdentifier("uls.preview.lifecycle.confirmProposeDraw")
                Button("Keep Playing") { screen = .actions }
                    .buttonStyle(GameTabletopActionButtonStyle(emphasis: .secondary, solidBackground: true))
                    .accessibilityIdentifier("uls.preview.lifecycle.keepPlaying")
            }
        }
    }

    private var drawVote: some View {
        VStack(alignment: .leading, spacing: 18) {
            explanation("Finish this game as a draw? Every active player must agree. If anyone declines, play continues.")

            VStack(spacing: 8) {
                Button("Agree to Draw") { screen = .actions }
                    .buttonStyle(GameTabletopActionButtonStyle(emphasis: .primary, solidBackground: true))
                    .accessibilityIdentifier("uls.preview.lifecycle.agreeDraw")
                Button("Keep Playing") { screen = .actions }
                    .buttonStyle(GameTabletopActionButtonStyle(emphasis: .secondary, solidBackground: true))
                    .accessibilityIdentifier("uls.preview.lifecycle.declineDraw")
            }
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
        detail: String,
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

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(GamePhysicalTurnPalette.primaryText)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("uls.preview.lifecycle.\(identifier)")
    }
}
#endif
