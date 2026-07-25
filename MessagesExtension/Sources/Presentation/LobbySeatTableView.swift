import SwiftUI

struct LobbySeatTableView: View {
    let model: LobbyScreenModel

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                seat(slots[0])
                seat(slots[1])
            }

            HStack(spacing: 12) {
                Rectangle()
                    .fill(LobbyPalette.openSeatEdge)
                    .frame(height: 1)

                VStack(spacing: 2) {
                    Text(tableCountLabel)
                        .font(GameTheme.headingFont.monospacedDigit())
                        .foregroundStyle(LobbyPalette.cream)

                    Text("Standard board")
                        .font(GameTheme.metaFont)
                        .foregroundStyle(LobbyPalette.mutedCream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)
                }
                .fixedSize(horizontal: true, vertical: false)

                Rectangle()
                    .fill(LobbyPalette.openSeatEdge)
                    .frame(height: 1)
            }

            HStack(spacing: 10) {
                seat(slots[2])
                seat(slots[3])
            }
        }
        .accessibilityIdentifier("uls.lobby.roster")
    }

    private func seat(_ slot: Seat) -> some View {
        HStack(spacing: 9) {
            Image(systemName: slot.systemImage)
                .font(.body.bold())
                .foregroundStyle(slot.foreground)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(slot.title)
                    .font(GameTheme.chipFont)
                    .foregroundStyle(slot.foreground)
                    .lineLimit(1)

                Text(slot.detail)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(slot.secondaryForeground)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 11)
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(slot.fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    slot.isOpen ? LobbyPalette.openSeatEdge : LobbyPalette.woodEdge.opacity(0.72),
                    style: StrokeStyle(lineWidth: 1, dash: slot.isOpen ? [5, 4] : [])
                )
        )
        .accessibilityElement(children: .combine)
    }

    private var tableCountLabel: String {
        if model.showsInviteEntryHero {
            return "1 player at the table"
        }
        let count = model.participants.count
        return count == 1 ? "1 player at the table" : "\(count) players at the table"
    }

    private var slots: [Seat] {
        var seats = model.participants.map { participant in
            Seat(
                title: participant.displayName,
                detail: participant.isLocalActor ? "You · \(participant.detailText)" : participant.detailText,
                systemImage: participant.isHost ? "crown.fill" : "checkmark.circle.fill",
                fill: participant.isHost ? LobbyPalette.wood : LobbyPalette.harbor,
                foreground: LobbyPalette.cream,
                secondaryForeground: LobbyPalette.cream.opacity(0.76),
                isOpen: false
            )
        }

        if model.showsInviteEntryHero {
            seats.append(hostSeat)
        } else if model.joinButton != nil {
            seats.append(pendingSeat)
        }

        while seats.count < 4 {
            seats.append(openSeat)
        }

        return Array(seats.prefix(4))
    }

    private var hostSeat: Seat {
        Seat(
            title: "Your seat",
            detail: "Host",
            systemImage: "crown.fill",
            fill: LobbyPalette.wood,
            foreground: LobbyPalette.cream,
            secondaryForeground: LobbyPalette.cream.opacity(0.76),
            isOpen: false
        )
    }

    private var pendingSeat: Seat {
        Seat(
            title: "Your seat",
            detail: "Ready to join",
            systemImage: "person.badge.plus",
            fill: LobbyPalette.clay.opacity(0.72),
            foreground: LobbyPalette.cream,
            secondaryForeground: LobbyPalette.cream.opacity(0.78),
            isOpen: false
        )
    }

    private var openSeat: Seat {
        Seat(
            title: "Open seat",
            detail: "Waiting",
            systemImage: "plus",
            fill: LobbyPalette.openSeat,
            foreground: LobbyPalette.mutedCream,
            secondaryForeground: LobbyPalette.mutedCream.opacity(0.78),
            isOpen: true
        )
    }
}

private struct Seat {
    let title: String
    let detail: String
    let systemImage: String
    let fill: Color
    let foreground: Color
    let secondaryForeground: Color
    let isOpen: Bool
}
