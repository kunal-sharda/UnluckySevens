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
