import SwiftUI

struct LobbyShellView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    let onSettingsTap: () -> Void
    let onTutorialTap: () -> Void

    #if DEBUG
    @AppStorage(LobbyInviteDirection.defaultsKey)
    private var inviteDirectionRawValue = LobbyInviteDirection.invitationCard.rawValue
    #endif

    init(
        viewModel: LobbyDriverViewModel,
        onSettingsTap: @escaping () -> Void = {},
        onTutorialTap: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onSettingsTap = onSettingsTap
        self.onTutorialTap = onTutorialTap
    }

    var body: some View {
        let model = viewModel.lobbyScreenModel

        Group {
            #if DEBUG
            if model.showsInviteEntryHero {
                LobbyInviteDirectionProbeView(
                    direction: LobbyInviteDirection(rawValue: inviteDirectionRawValue) ?? .invitationCard,
                    displayNameDraft: $viewModel.lobbyDisplayNameDraft,
                    settings: onSettingsTap,
                    tutorial: onTutorialTap,
                    invite: viewModel.inviteNewGame
                )
            } else {
                lobbyTable(model: model)
            }
            #else
            lobbyTable(model: model)
            #endif
        }
    }

    private func lobbyTable(model: LobbyScreenModel) -> some View {
        ZStack {
            LobbyPalette.background
                .ignoresSafeArea()

            LobbyHexWatermark()
                .foregroundStyle(LobbyPalette.feltHighlight.opacity(0.22))
                .frame(width: 240, height: 210)
                .rotationEffect(.degrees(-8))
                .offset(x: 128, y: -210)
                .accessibilityHidden(true)

            ScrollView(.vertical, showsIndicators: false) {
                LobbyTableCardView(
                    model: model,
                    displayNameDraft: $viewModel.lobbyDisplayNameDraft,
                    canSaveDisplayName: viewModel.canPublishLobbyDisplayName,
                    showSettings: onSettingsTap,
                    showTutorial: onTutorialTap,
                    invite: viewModel.inviteNewGame,
                    join: viewModel.publishLobbyJoinState,
                    saveDisplayName: viewModel.publishLobbyDisplayName,
                    start: viewModel.startGame
                )
                .padding(.horizontal, GameTheme.shellPadding)
                .padding(.vertical, 16)
            }
        }
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

private struct LobbyHexWatermark: View {
    var body: some View {
        VStack(spacing: -2) {
            HStack(spacing: 4) { hex; hex }
            HStack(spacing: 4) { hex; hex; hex }
            HStack(spacing: 4) { hex; hex }
        }
    }

    private var hex: some View {
        LobbyHexagonShape()
            .frame(width: 58, height: 50)
    }
}
