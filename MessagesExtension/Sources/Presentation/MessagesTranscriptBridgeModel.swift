import Foundation

struct MessagesTranscriptBridgeModel: Equatable {
    let title: String
    let status: String
    let detail: String
    let canOpenGame: Bool

    static func resolve(
        currentGameId: String?,
        recoveredGames: [ActiveGameRecoverySummary]
    ) -> MessagesTranscriptBridgeModel {
        let game = currentGameId.flatMap { currentGameId in
            recoveredGames.first { $0.gameId == currentGameId }
        }

        guard let game else {
            return MessagesTranscriptBridgeModel(
                title: "Unlucky Sevens",
                status: "Select a game bubble to continue",
                detail: "Player Record is available from the app drawer.",
                canOpenGame: false
            )
        }

        return MessagesTranscriptBridgeModel(
            title: game.title,
            status: game.subtitle,
            detail: game.detail,
            canOpenGame: true
        )
    }
}
