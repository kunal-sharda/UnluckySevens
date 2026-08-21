import Foundation

struct MessagesTranscriptBridgeModel: Equatable {
    let title: String
    let status: String
    let detail: String

    static func resolve(
        currentGameId: String?,
        recoveredGames: [ActiveGameRecoverySummary]
    ) -> MessagesTranscriptBridgeModel {
        let game = recoveredGames.first { $0.gameId == currentGameId }
            ?? recoveredGames.first(where: \.isCurrentSelection)
            ?? recoveredGames.first(where: \.isLastActive)

        guard let game else {
            return MessagesTranscriptBridgeModel(
                title: "Unlucky Sevens",
                status: "Open the game to continue",
                detail: "Your saved games remain available in Messages."
            )
        }

        return MessagesTranscriptBridgeModel(
            title: game.title,
            status: game.subtitle,
            detail: game.detail
        )
    }
}
