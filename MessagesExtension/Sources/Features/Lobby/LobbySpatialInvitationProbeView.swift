import SwiftUI

struct LobbySpatialInvitationProbeView: View {
    let model: LobbyScreenModel
    @Binding var displayNameDraft: String
    let settings: () -> Void
    let tutorial: () -> Void
    let invite: () -> Void

    var body: some View {
        ZStack {
            GameTheme.appBackground
                .ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        header

                        lobbyScene
                            .frame(height: min(360, max(336, proxy.size.height * 0.44)))

                        rulesSummary

                        Color.clear
                            .frame(height: 20)
                            .accessibilityHidden(true)

                        playingAs

                        if let button = model.inviteButton {
                            LobbyInvitePrimaryButton(model: button, action: invite)
                                .padding(.top, GameTheme.blockSpacing)
                        }
                    }
                    .frame(minHeight: max(0, proxy.size.height - 36), alignment: .top)
                    .padding(.horizontal, 20)
                    .padding(.top, GameTheme.inlineSpacing)
                    .padding(.bottom, 28)
                }
            }
        }
        .accessibilityIdentifier("uls.lobby.tableSurface")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            HStack {
                Spacer(minLength: 0)

                Button(action: tutorial) {
                    Label("Tutorial", systemImage: "book.closed.fill")
                        .font(GameTheme.metaFont.bold())
                        .foregroundStyle(LobbyInvitePalette.mutedPaper)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens a short game tutorial")
                .accessibilityIdentifier("uls.lobby.tutorial")
            }

            Text(model.title)
                .font(GameTheme.titleFont)
                .foregroundStyle(LobbyInvitePalette.mutedPaper)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("uls.lobby.inviteTitle")
        }
    }

    private var lobbyScene: some View {
        GeometryReader { proxy in
            let centerX = proxy.size.width / 2
            let centerY = proxy.size.height / 2

            ZStack {
                LobbyRobberIdentityMark()
                    .frame(width: 96, height: 168)
                    .position(x: centerX, y: centerY)

                seat(title: "You", detail: "Host", isHost: true)
                    .position(x: centerX, y: 44)

                seat(title: "Open", detail: "Seat", isHost: false)
                    .position(x: 48, y: centerY)

                seat(title: "Open", detail: "Seat", isHost: false)
                    .position(x: proxy.size.width - 48, y: centerY)

                seat(title: "Optional", detail: "Seat", isHost: false)
                    .position(x: centerX, y: proxy.size.height - 44)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.lobby.roster")
    }

    private func seat(title: String, detail: String, isHost: Bool) -> some View {
        VStack(spacing: 4) {
            LobbyGamePieceMarker(isHost: isHost)
                .frame(width: 42, height: 50)

            Text(title)
                .font(GameTheme.chipFont)
                .foregroundStyle(LobbyInvitePalette.mutedPaper)

            Text(detail)
                .font(.caption2)
                .foregroundStyle(LobbyInvitePalette.mutedPaper.opacity(0.68))
        }
        .frame(width: 80)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isHost ? "You, Host" : "\(title) seat, \(detail)")
    }

    private var rulesSummary: some View {
        Button(action: settings) {
            HStack(spacing: GameTheme.inlineSpacing) {
                Text("Standard")
                Text("·")
                    .foregroundStyle(GameTheme.accent)
                Text("Balanced")
                Text("·")
                    .foregroundStyle(GameTheme.accent)
                Text("10 points")

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .accessibilityHidden(true)
            }
            .font(GameTheme.metaFont.bold())
            .foregroundStyle(LobbyInvitePalette.mutedPaper)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Game Settings, Standard rules, Balanced board, 10 points")
        .accessibilityHint("Shows the rules selected for this game")
        .accessibilityIdentifier("uls.lobby.gameSettings")
    }

    private var playingAs: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Playing as")
                .font(GameTheme.metaFont.bold())
                .foregroundStyle(LobbyInvitePalette.mutedPaper.opacity(0.72))

            HStack(spacing: GameTheme.inlineSpacing) {
                TextField(
                    "Display Name",
                    text: $displayNameDraft,
                    prompt: Text(model.nameEditor?.placeholder ?? "Name")
                        .foregroundStyle(LobbyInvitePalette.mutedPaper.opacity(0.72))
                )
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .submitLabel(.done)
                .font(GameTheme.bodyFont.bold())
                .foregroundStyle(LobbyInvitePalette.mutedPaper)
                .tint(GameTheme.accent)
                .accessibilityIdentifier("uls.lobby.nameField")

                Image(systemName: "pencil")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(LobbyInvitePalette.mutedPaper.opacity(0.72))
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 44)

            Rectangle()
                .fill(LobbyInvitePalette.mutedPaper.opacity(0.42))
                .frame(height: 1)
        }
    }
}

private struct LobbyGamePieceMarker: View {
    let isHost: Bool

    var body: some View {
        Canvas { context, size in
            let fill = isHost ? GameTheme.accent : LobbyInvitePalette.controlSurface
            let stroke = isHost ? GameTheme.outline : LobbyInvitePalette.mutedPaper.opacity(0.56)
            let lineWidth: CGFloat = isHost ? 1.5 : 1.25

            let headDiameter = size.width * 0.42
            let headRect = CGRect(
                x: (size.width - headDiameter) / 2,
                y: 1,
                width: headDiameter,
                height: headDiameter
            )
            context.fill(Path(ellipseIn: headRect), with: .color(fill))
            context.stroke(Path(ellipseIn: headRect), with: .color(stroke), lineWidth: lineWidth)

            var body = Path()
            body.move(to: CGPoint(x: size.width * 0.34, y: size.height * 0.38))
            body.addQuadCurve(
                to: CGPoint(x: size.width * 0.22, y: size.height * 0.84),
                control: CGPoint(x: size.width * 0.20, y: size.height * 0.60)
            )
            body.addQuadCurve(
                to: CGPoint(x: size.width * 0.78, y: size.height * 0.84),
                control: CGPoint(x: size.width * 0.50, y: size.height * 0.98)
            )
            body.addQuadCurve(
                to: CGPoint(x: size.width * 0.66, y: size.height * 0.38),
                control: CGPoint(x: size.width * 0.80, y: size.height * 0.60)
            )
            body.closeSubpath()
            context.fill(body, with: .color(fill))
            context.stroke(body, with: .color(stroke), lineWidth: lineWidth)

            let base = RoundedRectangle(cornerRadius: size.width * 0.12)
                .path(in: CGRect(
                    x: size.width * 0.15,
                    y: size.height * 0.80,
                    width: size.width * 0.70,
                    height: size.height * 0.17
                ))
            context.fill(base, with: .color(fill))
            context.stroke(base, with: .color(stroke), lineWidth: lineWidth)
        }
        .accessibilityHidden(true)
    }
}
