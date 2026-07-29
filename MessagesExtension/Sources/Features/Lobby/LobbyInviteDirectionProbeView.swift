import SwiftUI

struct LobbyInviteDirectionProbeView: View {
    let direction: LobbyInviteDirection
    let model: LobbyScreenModel
    @Binding var displayNameDraft: String
    let canSaveDisplayName: Bool
    let settings: () -> Void
    let tutorial: () -> Void
    let games: (() -> Void)?
    let invite: () -> Void
    let join: () -> Void
    let saveDisplayName: () -> Void
    let start: () -> Void

    var body: some View {
        Group {
            switch direction {
            case .setupCard:
                LobbySetupCardProbeView(
                    displayNameDraft: $displayNameDraft,
                    invite: invite
                )
            case .invitationCard:
                LobbyInvitationCardView(
                    model: model,
                    displayNameDraft: $displayNameDraft,
                    canSaveDisplayName: canSaveDisplayName,
                    showSettings: settings,
                    showTutorial: tutorial,
                    showGames: games,
                    invite: invite,
                    join: join,
                    saveDisplayName: saveDisplayName,
                    start: start
                )
            case .tabletopCandidate:
                LobbyTabletopInvitationProbeView(
                    model: model,
                    displayNameDraft: $displayNameDraft,
                    settings: settings,
                    tutorial: tutorial,
                    invite: invite
                )
            case .artifactCandidate:
                LobbyArtifactInvitationProbeView(
                    model: model,
                    displayNameDraft: $displayNameDraft,
                    settings: settings,
                    tutorial: tutorial,
                    invite: invite
                )
            case .spatialCandidate:
                LobbySpatialInvitationProbeView(
                    model: model,
                    displayNameDraft: $displayNameDraft,
                    settings: settings,
                    tutorial: tutorial,
                    invite: invite
                )
            case .cocktailTableCandidate:
                LobbyCocktailTableView(
                    model: model,
                    settingsSummary: GameSettingsSummary(),
                    boardStrategy: BoardStrategyDefaults.newGame,
                    displayNameDraft: $displayNameDraft,
                    canSaveDisplayName: canSaveDisplayName,
                    settings: settings,
                    tutorial: tutorial,
                    games: games,
                    invite: invite,
                    join: join,
                    saveDisplayName: saveDisplayName,
                    start: start
                )
            }
        }
        .accessibilityIdentifier("uls.lobby.inviteDirection.\(direction.rawValue)")
    }
}
