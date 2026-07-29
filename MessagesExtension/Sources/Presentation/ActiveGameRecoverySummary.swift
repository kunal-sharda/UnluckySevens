import Foundation
import ULS_CoreGame

struct ActiveGameRecoverySummary: Identifiable, Equatable {
    let id: String
    let gameId: String
    let title: String
    let subtitle: String
    let detail: String
    let isFinished: Bool
    let isLastActive: Bool
    let isCurrentSelection: Bool
}

enum ActiveGameRecoveryModelBuilder {
    static func build(
        from state: CoreGameStateV1,
        updatedAt: TimeInterval,
        isLastActive: Bool,
        isCurrentSelection: Bool
    ) -> ActiveGameRecoverySummary {
        let currentPlayerName = PlayerPseudonymResolver.displayName(for: state.currentPlayer, in: state)
        let playerNames = state.roster.map {
            PlayerPseudonymResolver.displayName(for: $0, in: state)
        }

        let subtitle: String
        switch state.phase {
        case .lobby:
            subtitle = "Waiting for players"
        case .setup:
            subtitle = "\(currentPlayerName) is placing"
        case .turn:
            if let lastResigned = state.resignedPlayers.last {
                subtitle = "\(PlayerPseudonymResolver.displayName(for: lastResigned, in: state)) resigned · \(currentPlayerName)'s turn"
            } else if let vote = state.drawVote {
                subtitle = "Draw proposed by \(PlayerPseudonymResolver.displayName(for: vote.proposedBy, in: state))"
            } else {
                subtitle = "\(currentPlayerName)'s turn"
            }
        case .gameOver:
            switch state.gameResult?.reason {
            case .draw:
                subtitle = "Draw agreed"
            case .hostEnded:
                subtitle = "Ended by host"
            case .victory:
                let winnerNames = state.gameResult?.winnerPlayers.map {
                    PlayerPseudonymResolver.displayName(for: $0, in: state)
                } ?? []
                subtitle = winnerNames.isEmpty
                    ? "Game finished"
                    : "\(Self.joinedNames(winnerNames)) won"
            case nil:
                subtitle = "Game finished"
            }
        }

        return ActiveGameRecoverySummary(
            id: state.gameId,
            gameId: state.gameId,
            title: Self.joinedNames(playerNames),
            subtitle: subtitle,
            detail: "Updated \(Date(timeIntervalSince1970: updatedAt).formatted(date: .abbreviated, time: .shortened))",
            isFinished: state.phase == .gameOver,
            isLastActive: isLastActive,
            isCurrentSelection: isCurrentSelection
        )
    }

    private static func joinedNames(_ names: [String]) -> String {
        switch names.count {
        case 0:
            return "Unknown players"
        case 1:
            return names[0]
        case 2:
            return "\(names[0]) & \(names[1])"
        default:
            return "\(names.dropLast().joined(separator: ", ")) & \(names.last ?? "")"
        }
    }
}
