struct TranscriptTradeVisual: Equatable {
    let offer: GameTradeOfferSummary
    let participantStatuses: [GameTradeParticipantStatus]
    let recipientScopeLabel: String
    let playerOrder: [String]
}
