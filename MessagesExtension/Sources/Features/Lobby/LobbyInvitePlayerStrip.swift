import SwiftUI

struct LobbyInvitePlayerStrip: View {
    let model: LobbyScreenModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(slots.enumerated()), id: \.offset) { index, slot in
                if index > 0 {
                    Divider()
                        .padding(.leading, 52)
                }

                playerRow(slot)
            }

            Text(" ")
                .font(GameTheme.metaFont)
                .padding(.top, GameTheme.inlineSpacing)
                .hidden()
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("uls.lobby.roster")
    }

    private func playerRow(_ slot: Slot) -> some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            Image(systemName: slot.systemImage)
                .font(.body.bold())
                .foregroundStyle(slot.isHost ? GameTheme.ink : GameTheme.mutedInk)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(slot.isHost ? GameTheme.accent : LobbyInvitePalette.controlSurface)
                }
                .overlay {
                    Circle()
                        .stroke(
                            slot.isHost ? GameTheme.outline : GameTheme.outline.opacity(0.26),
                            lineWidth: slot.isHost ? 1.5 : 1
                        )
                }
                .accessibilityHidden(true)

            Text(slot.label)
                .font(GameTheme.bodyFont.bold())
                .foregroundStyle(GameTheme.ink)
                .lineLimit(1)

            Spacer(minLength: GameTheme.inlineSpacing)

            Text(slot.detail)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .lineLimit(1)
        }
        .frame(minHeight: 52)
        .accessibilityElement(children: .combine)
    }

    private var slots: [Slot] {
        if model.showsInviteEntryHero {
            return [
                Slot(label: "You", detail: "Host", systemImage: "person.fill", isHost: true),
                Slot(label: "Friend", detail: "Open seat", systemImage: "plus", isHost: false),
                Slot(label: "Friend", detail: "Open seat", systemImage: "plus", isHost: false),
                Slot(label: "Optional", detail: "Fourth player", systemImage: "plus", isHost: false),
            ]
        }

        var result = model.participants.map { participant in
            Slot(
                label: participant.displayName,
                detail: participant.isLocalActor
                    ? "You · \(participant.detailText)"
                    : participant.detailText,
                systemImage: participant.isHost ? "crown.fill" : "checkmark",
                isHost: participant.isHost
            )
        }

        if model.joinButton != nil, result.count < 4 {
            result.append(
                Slot(
                    label: "You",
                    detail: "Ready to join",
                    systemImage: "person.badge.plus",
                    isHost: false
                )
            )
        }

        while result.count < 4 {
            let isOptional = result.count == 3
            result.append(
                Slot(
                    label: isOptional ? "Optional" : "Friend",
                    detail: isOptional ? "Fourth player" : "Open seat",
                    systemImage: "plus",
                    isHost: false
                )
            )
        }

        return Array(result.prefix(4))
    }
}

private struct Slot {
    let label: String
    let detail: String
    let systemImage: String
    let isHost: Bool
}
