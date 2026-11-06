import SwiftUI

struct GameTableSeatsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let players: [GameInfoPlayerSummary]
    var compact = false
    let onShowPlayers: () -> Void

    var body: some View {
        VStack {
            row(Array(players.prefix(2)))
            Spacer(minLength: 0)
            row(Array(players.dropFirst(2).prefix(2)))
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.tabletop.seats")
    }

    private func row(_ seats: [GameInfoPlayerSummary]) -> some View {
        HStack(alignment: .top) {
            ForEach(Array(seats.enumerated()), id: \.element.id) { index, player in
                if index > 0 { Spacer(minLength: 0) }
                seat(player)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func seat(_ player: GameInfoPlayerSummary) -> some View {
        let mark = GamePlayerMark.resolve(owner: player.id, playerOrder: players.map(\.id))
        return Button(action: onShowPlayers) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Path(mark.path(in: CGRect(x: 0, y: 0, width: 9, height: 9)))
                        .fill(Color(red: player.playerTint.red, green: player.playerTint.green, blue: player.playerTint.blue))
                        .overlay { Path(mark.path(in: CGRect(x: 0, y: 0, width: 9, height: 9))).stroke(GameTheme.surface, lineWidth: 1) }
                        .frame(width: 9, height: 9)
                    Text(player.displayName)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize && !compact ? 2 : 1)
                        .minimumScaleFactor(0.8)
                }
                Text(compact ? "\(player.victoryPoints) VP" : "\(player.victoryPoints) public VP\(player.isResigned ? " · Left" : player.isLocalPlayer ? " · You" : "")")
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            }
            .font(.caption2.weight(player.isCurrentPlayer ? .bold : .regular))
            .foregroundStyle(GameTheme.surface)
            .padding(5)
            .frame(width: compact ? 64 : dynamicTypeSize.isAccessibilitySize ? 140 : 110, alignment: .leading)
            .frame(minHeight: 44)
            .background(GameTheme.felt.opacity(0.94), in: RoundedRectangle(cornerRadius: 5))
            .overlay {
                if player.isCurrentPlayer {
                    RoundedRectangle(cornerRadius: 5).stroke(GameTheme.surface, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mark.name), \(player.displayName), \(player.victoryPoints) public victory points\(player.isLocalPlayer ? ", you" : "")\(player.isCurrentPlayer ? ", current turn" : "")\(player.isResigned ? ", spectating" : "")")
        .accessibilityHint("Opens Players and game information")
        .accessibilityIdentifier("uls.tabletop.seat.\(mark.rawValue)")
    }
}
