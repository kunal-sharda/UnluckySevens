import SwiftUI

struct GamesLibraryView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    let dismiss: () -> Void
    @State private var pendingLifecycleConfirmation: LifecycleConfirmation?

    private enum LifecycleConfirmation {
        case resignation(ActiveGameRecoverySummary)
        case hostEnd(ActiveGameRecoverySummary)

        var title: String {
            switch self {
            case .resignation:
                return "Resign from this game?"
            case .hostEnd:
                return "End this game?"
            }
        }

        var game: ActiveGameRecoverySummary {
            switch self {
            case let .resignation(game), let .hostEnd(game):
                game
            }
        }

        var destructiveTitle: String {
            switch self {
            case .resignation:
                "Resign"
            case .hostEnd:
                "End Game Anyway"
            }
        }
    }

    var body: some View {
        ZStack {
            GameTheme.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.recoveredGames.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: GameTheme.sectionSpacing) {
                            gamesSection(
                                title: "Active",
                                games: viewModel.activeRecoveredGames
                            )
                            gamesSection(
                                title: "Finished",
                                games: viewModel.finishedRecoveredGames
                            )
                        }
                        .padding(GameTheme.shellPadding)
                    }
                }
            }

            if let pendingLifecycleConfirmation {
                GameLifecycleConfirmationView(
                    title: pendingLifecycleConfirmation.title,
                    message: confirmationMessage(for: pendingLifecycleConfirmation),
                    destructiveTitle: pendingLifecycleConfirmation.destructiveTitle,
                    showsProposeDraw: shouldOfferDraw(for: pendingLifecycleConfirmation),
                    onKeepPlaying: dismissLifecycleConfirmation,
                    onProposeDraw: proposeDraw,
                    onConfirm: confirmLifecycleAction
                )
                .zIndex(2)
            }
        }
        .accessibilityIdentifier("uls.games.library")
    }

    private func confirmationMessage(for confirmation: LifecycleConfirmation) -> String {
        switch confirmation {
        case .resignation:
            "You will leave active play. Your pieces stay on the board, and the remaining players continue."
        case .hostEnd:
            shouldOfferDraw(for: confirmation)
                ? "A draw gives every active player a say. You can still end the game immediately as host."
                : "Ending is unilateral. Final scores remain visible, but no winner is declared."
        }
    }

    private func shouldOfferDraw(for confirmation: LifecycleConfirmation) -> Bool {
        guard case let .hostEnd(game) = confirmation else { return false }
        return viewModel.shouldOfferDrawBeforeHostEnd(game.gameId)
            && viewModel.canProposeDraw(for: game.gameId)
    }

    private func dismissLifecycleConfirmation() {
        pendingLifecycleConfirmation = nil
    }

    private func proposeDraw() {
        guard case let .hostEnd(game) = pendingLifecycleConfirmation else { return }
        viewModel.proposeDraw(for: game.gameId)
        pendingLifecycleConfirmation = nil
    }

    private func confirmLifecycleAction() {
        guard let pendingLifecycleConfirmation else { return }

        switch pendingLifecycleConfirmation {
        case let .resignation(game):
            viewModel.resignRecoveredGame(game.gameId)
        case let .hostEnd(game):
            viewModel.hostEndGame(game.gameId)
        }

        self.pendingLifecycleConfirmation = nil
    }

    private var header: some View {
        ZStack {
            Text("Your Games")
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.surface)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: GameTheme.inlineSpacing) {
                Button("Back", systemImage: "chevron.left", action: dismiss)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .frame(minWidth: 84, minHeight: 44, alignment: .leading)

                Spacer()

                Text("\(viewModel.recoveredGames.count)")
                    .font(GameTheme.metaFont.bold())
                    .monospacedDigit()
                    .foregroundStyle(GameTheme.surface.opacity(0.72))
                    .frame(minWidth: 84, minHeight: 44, alignment: .trailing)
                    .accessibilityLabel("\(viewModel.recoveredGames.count) saved games")
            }
        }
        .foregroundStyle(GameTheme.surface)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, GameTheme.shellPadding)
        .padding(.vertical, GameTheme.inlineSpacing)
        .background(GameTheme.feltRaised)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Saved Games",
            systemImage: "die.face.5",
            description: Text("Start or open an Unlucky Sevens game in this conversation.")
        )
        .foregroundStyle(GameTheme.surface)
    }

    @ViewBuilder
    private func gamesSection(
        title: String,
        games: [ActiveGameRecoverySummary]
    ) -> some View {
        if !games.isEmpty {
            VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                Text(title)
                    .font(GameTheme.metaFont.weight(.bold))
                    .foregroundStyle(GameTheme.surface.opacity(0.76))
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)

                ForEach(games) { game in
                    gameRow(game)
                }
            }
            .accessibilityIdentifier("uls.games.section.\(title.lowercased())")
        }
    }

    private func gameRow(_ game: ActiveGameRecoverySummary) -> some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            Button {
                viewModel.resumeRecoveredGame(game.gameId)
                dismiss()
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(game.title)
                            .font(GameTheme.metaFont.weight(.semibold))
                            .lineLimit(1)

                        if game.isCurrentSelection {
                            Text("Current")
                                .font(.caption2.bold())
                                .foregroundStyle(GameTheme.accent)
                        }
                    }

                    Text(game.subtitle)
                        .font(GameTheme.chipFont)
                        .foregroundStyle(GameTheme.mutedInk)
                        .lineLimit(2)

                    Text(game.detail)
                        .font(.caption2)
                        .foregroundStyle(GameTheme.mutedInk)
                }
                .foregroundStyle(GameTheme.ink)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("uls.games.open.\(game.gameId)")
            .accessibilityLabel(
                [
                    game.title,
                    game.subtitle,
                    game.isCurrentSelection ? "Current game" : nil,
                ]
                .compactMap { $0 }
                .joined(separator: ", ")
            )

            Menu {
                Button("Open", systemImage: "arrow.up.right.square") {
                    viewModel.resumeRecoveredGame(game.gameId)
                    dismiss()
                }

                Button("Resend Latest State", systemImage: "paperplane") {
                    viewModel.resendRecoveredGame(game.gameId)
                }
                .disabled(!viewModel.canResendRecoveredGame(game.gameId))

                if !game.isFinished {
                    if viewModel.canVoteOnDraw(for: game.gameId) {
                        Button("Agree to Draw", systemImage: "hand.thumbsup") {
                            viewModel.voteOnDraw(for: game.gameId, approve: true)
                        }
                        Button("Decline Draw", systemImage: "hand.thumbsdown") {
                            viewModel.voteOnDraw(for: game.gameId, approve: false)
                        }
                    } else if viewModel.canProposeDraw(for: game.gameId) {
                        Button("Propose Draw", systemImage: "hand.raised") {
                            viewModel.proposeDraw(for: game.gameId)
                        }
                    }

                    if viewModel.canResignRecoveredGame(game.gameId) {
                        Button("Resign", systemImage: "figure.walk.departure", role: .destructive) {
                            pendingLifecycleConfirmation = .resignation(game)
                        }
                    }

                    if viewModel.canHostEndGame(game.gameId) {
                        Button("End Game", systemImage: "xmark.octagon", role: .destructive) {
                            pendingLifecycleConfirmation = .hostEnd(game)
                        }
                    }
                }

                Button("Archive", systemImage: "archivebox", role: .destructive) {
                    viewModel.archiveRecoveredGame(game.gameId)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(GameTheme.ink)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Actions for \(game.title), \(game.subtitle)")
            .accessibilityIdentifier("uls.games.actions.\(game.gameId)")
        }
        .padding(GameTheme.compactPadding)
        .background {
            RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                .fill(GameTheme.surface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                .stroke(GameTheme.outline.opacity(0.18), lineWidth: 1)
        }
    }
}
