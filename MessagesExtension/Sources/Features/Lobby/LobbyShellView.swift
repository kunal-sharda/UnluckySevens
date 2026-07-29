import SwiftUI

struct LobbyShellView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    let onSettingsTap: () -> Void
    let onTutorialTap: () -> Void
    let onGamesTap: () -> Void

    init(
        viewModel: LobbyDriverViewModel,
        onSettingsTap: @escaping () -> Void = {},
        onTutorialTap: @escaping () -> Void = {},
        onGamesTap: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onSettingsTap = onSettingsTap
        self.onTutorialTap = onTutorialTap
        self.onGamesTap = onGamesTap
    }

    var body: some View {
        let model = viewModel.lobbyScreenModel

        cocktailTable(model: model)
    }

    private func cocktailTable(model: LobbyScreenModel) -> some View {
        LobbyCocktailTableView(
            model: model,
            settingsSummary: GameSettingsSummary(boardStrategy: viewModel.boardStrategy),
            boardStrategy: viewModel.boardStrategy,
            displayNameDraft: $viewModel.lobbyDisplayNameDraft,
            canSaveDisplayName: viewModel.canPublishLobbyDisplayName,
            settings: onSettingsTap,
            tutorial: onTutorialTap,
            games: onGamesTap,
            invite: viewModel.inviteNewGame,
            join: viewModel.publishLobbyJoinState,
            saveDisplayName: viewModel.publishLobbyDisplayName,
            start: viewModel.startGame
        )
        .id(lobbyCardIdentity(model))
    }

    private func lobbyCardIdentity(_ model: LobbyScreenModel) -> String {
        let participants = model.participants.map(\.id).joined(separator: ",")
        return "\(model.title)|\(participants)"
    }

}

struct LobbyTableMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LobbyPalette.clay)

            HStack(spacing: 3) {
                LobbyHexagonShape()
                    .fill(LobbyPalette.cream)
                LobbyHexagonShape()
                    .fill(LobbyPalette.cream.opacity(0.78))
            }
            .frame(width: 25, height: 16)
            .offset(y: -6)

            Image(systemName: "dice.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(LobbyPalette.cream)
                .offset(y: 9)
        }
    }
}

struct LobbyHexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.75))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.75))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25))
        path.closeSubpath()
        return path
    }
}
