import SwiftUI

struct LobbyShellView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var showsRulesHelp = false
    #if DEBUG
    @AppStorage(LobbyInviteDirection.defaultsKey)
    private var inviteDirectionRawValue = LobbyInviteDirection.invitationCard.rawValue
    #endif

    var body: some View {
        let model = viewModel.lobbyScreenModel

        Group {
            #if DEBUG
            if model.showsInviteEntryHero {
                LobbyInviteDirectionProbeView(
                    direction: LobbyInviteDirection(rawValue: inviteDirectionRawValue) ?? .invitationCard,
                    displayNameDraft: $viewModel.lobbyDisplayNameDraft,
                    tutorial: showRules,
                    invite: viewModel.inviteNewGame
                )
            } else {
                lobbyTable(model: model)
            }
            #else
            lobbyTable(model: model)
            #endif
        }
        .sheet(isPresented: $showsRulesHelp) {
            LobbyRulesHelpSheet()
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
                    showRules: showRules,
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

    private func showRules() {
        showsRulesHelp = true
    }
}

enum LobbyPalette {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.10, green: 0.23, blue: 0.20),
            Color(red: 0.06, green: 0.15, blue: 0.14),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let feltHighlight = Color(red: 0.27, green: 0.48, blue: 0.39)
    static let cream = Color(red: 0.97, green: 0.91, blue: 0.78)
    static let mutedCream = Color(red: 0.77, green: 0.74, blue: 0.64)
    static let ink = Color(red: 0.12, green: 0.09, blue: 0.06)
    static let clay = Color(red: 0.72, green: 0.31, blue: 0.15)
    static let moss = Color(red: 0.39, green: 0.55, blue: 0.29)
    static let harbor = Color(red: 0.25, green: 0.43, blue: 0.46)
    static let wood = Color(red: 0.47, green: 0.30, blue: 0.17)
    static let woodEdge = Color(red: 0.24, green: 0.14, blue: 0.08)
    static let openSeat = Color.white.opacity(0.08)
    static let openSeatEdge = cream.opacity(0.34)
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

private struct LobbyRulesHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Text("Build roads, settlements, and cities by collecting resources from dice rolls.")
                    .font(GameTheme.bodyFont)

                rule("Roll", systemImage: "dice.fill", detail: "Dice decide which board tiles produce resources.")
                rule("Trade", systemImage: "arrow.left.arrow.right", detail: "Swap resources with the table when you need a better hand.")
                rule("Build", systemImage: "hammer.fill", detail: "Spend resources to expand toward ten victory points.")
                rule("Robber", systemImage: "figure.wave", detail: "A seven moves the robber and can force large hands to discard.")
            }
            .navigationTitle("Game rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func rule(_ title: String, systemImage: String, detail: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(GameTheme.headingFont)
                Text(detail).font(GameTheme.metaFont).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(GameTheme.accent)
        }
    }
}
