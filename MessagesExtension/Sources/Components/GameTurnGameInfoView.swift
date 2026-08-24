import SwiftUI

struct GameTurnGameInfoView: View {
    /// A non-zero renderer signal keeps the SpriteKit-owned modal veil active.
    /// The centered panel no longer reserves or covers a bottom-board region.
    static let boardClearanceHeight: CGFloat = 1

    let model: GameInfoModel
    let canProposeDraw: Bool
    let canVoteOnDraw: Bool
    let canResign: Bool
    let canHostEnd: Bool
    let shouldOfferDrawBeforeHostEnd: Bool
    let onPlayerRecordTap: () -> Void
    let onProposeDraw: () -> Void
    let onVoteOnDraw: (Bool) -> Void
    let onResign: () -> Void
    let onHostEnd: () -> Void
    let onClose: () -> Void
    @State private var pendingConfirmation: Confirmation?

    private enum Confirmation {
        case resign
        case hostEnd
    }

    static func preferredHeight(for model: GameInfoModel) -> CGFloat {
        let visiblePlayerCount = min(model.players.count, 4)
        let playerRowsHeight = CGFloat(visiblePlayerCount) * 44
        let playerSpacingHeight = CGFloat(max(visiblePlayerCount - 1, 0)) * 6
        let recapHeight: CGFloat = model.recapText?.isEmpty == false ? 22 : 0

        return 44 + 8 + playerRowsHeight + playerSpacingHeight + recapHeight + 12
    }

    var body: some View {
        ZStack {
            GameTheme.felt.opacity(0.98)

            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Text("Players")
                        .font(.headline)
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                        .frame(maxWidth: .infinity)

                    HStack {
                        Button(
                            "Player Record",
                            systemImage: "chart.bar.xaxis",
                            action: onPlayerRecordTap
                        )
                        .labelStyle(.iconOnly)
                        .font(.headline)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        .accessibilityHint("Shows read-only results saved on this device")
                        .accessibilityIdentifier("uls.gameInfo.playerRecord")

                        Spacer(minLength: 0)

                        if canProposeDraw || canVoteOnDraw || canResign || canHostEnd {
                            lifecycleMenu
                        }

                        Button(
                            "Close game information",
                            systemImage: "xmark",
                            action: onClose
                        )
                        .labelStyle(.iconOnly)
                        .font(.headline)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("uls.gameInfo.close")
                    }
                }

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 6) {
                        ForEach(model.players) { player in
                            GameTurnGameInfoPlayerRow(player: player)
                        }

                        if let recapText = model.recapText, !recapText.isEmpty {
                            Label(recapText, systemImage: "clock.arrow.circlepath")
                                .font(.caption)
                                .foregroundStyle(GameTheme.surface.opacity(0.82))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 2)
                        }
                    }
                    .accessibilityIdentifier("uls.gameInfo.playerList")
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .padding(14)

            if let pendingConfirmation {
                GameLifecycleConfirmationView(
                    title: pendingConfirmation == .resign
                        ? "Resign from this game?"
                        : "End this game?",
                    message: confirmationMessage(for: pendingConfirmation),
                    destructiveTitle: pendingConfirmation == .resign ? "Resign" : "End Game Anyway",
                    showsProposeDraw: pendingConfirmation == .hostEnd && shouldOfferDrawBeforeHostEnd && canProposeDraw,
                    onKeepPlaying: { self.pendingConfirmation = nil },
                    onProposeDraw: {
                        onProposeDraw()
                        self.pendingConfirmation = nil
                    },
                    onConfirm: {
                        if pendingConfirmation == .resign { onResign() } else { onHostEnd() }
                        self.pendingConfirmation = nil
                    }
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.74), lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.30), radius: 8, y: 3)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.turn.gameInfo")
        .gameTutorialTarget(.gameInfo)
    }

    private var lifecycleMenu: some View {
        Menu {
            if canVoteOnDraw {
                Button("Agree to Draw", systemImage: "hand.thumbsup") { onVoteOnDraw(true) }
                Button("Decline Draw", systemImage: "hand.thumbsdown") { onVoteOnDraw(false) }
            } else if canProposeDraw {
                Button("Propose Draw", systemImage: "hand.raised", action: onProposeDraw)
            }
            if canResign {
                Button("Resign", systemImage: "figure.walk.departure", role: .destructive) {
                    pendingConfirmation = .resign
                }
            }
            if canHostEnd {
                Button("End Game", systemImage: "xmark.octagon", role: .destructive) {
                    pendingConfirmation = .hostEnd
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.headline)
                .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Current game actions")
        .accessibilityIdentifier("uls.gameInfo.lifecycleActions")
    }

    private func confirmationMessage(for confirmation: Confirmation) -> String {
        switch confirmation {
        case .resign:
            "You will leave active play. Your pieces stay on the board, and the remaining players continue."
        case .hostEnd:
            shouldOfferDrawBeforeHostEnd
                ? "A draw gives every active player a say. You can still end the game immediately as host."
                : "Ending is unilateral. Final scores remain visible, but no winner is declared."
        }
    }
}

private struct GameTurnGameInfoPlayerRow: View {
    let player: GameInfoPlayerSummary

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(
                    Color(
                        red: player.playerTint.red,
                        green: player.playerTint.green,
                        blue: player.playerTint.blue
                    )
                )
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(GameTheme.surface.opacity(0.55), lineWidth: 1))

            VStack(alignment: .leading, spacing: 1) {
                Text(player.displayName + (player.isLocalPlayer ? " · You" : ""))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(GameTheme.surface)

                if !player.awardLabels.isEmpty {
                    Text(player.awardLabels.joined(separator: " · "))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(GameTheme.surface.opacity(0.74))
                }
            }

            Spacer()

            Text("\(player.victoryPoints) VP")
                .font(.caption.weight(.bold))
                .foregroundStyle(GameTheme.surface)
                .monospacedDigit()

            Text("\(player.resourceCardCount) hand · \(player.developmentCardCount) dev")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(GameTheme.surface.opacity(0.76))
                .monospacedDigit()

            if player.isCurrentPlayer {
                Image(systemName: "circle.inset.filled")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(GameTheme.surface)
                    .accessibilityLabel("Current turn")
            }
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 34)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(GameTheme.surface.opacity(player.isCurrentPlayer ? 0.42 : 0.14), lineWidth: player.isCurrentPlayer ? 2 : 1)
        }
    }
}
