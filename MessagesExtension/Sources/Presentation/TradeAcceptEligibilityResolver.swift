import ULS_CoreGame

enum TradeAcceptEligibilityReason: String, Equatable {
    case eligible
    case stateUnavailable
    case actorUnavailable
    case turnUnavailable
    case offerMissing
    case responderInvalid
    case responderNotTargeted
    case responderAlreadyResponded
    case offerNoLongerFunded
    case responderInsufficientResources
}

enum TradeAcceptEligibilityResolver {
    static func resolve(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> TradeAcceptEligibilityReason {
        guard let state else {
            return .stateUnavailable
        }
        guard let actingAs else {
            return .actorUnavailable
        }

        switch state.tradeAcceptEligibility(for: actingAs) {
        case .eligible:
            return .eligible
        case .turnUnavailable:
            return .turnUnavailable
        case .offerMissing:
            return .offerMissing
        case .responderInvalid:
            return .responderInvalid
        case .responderNotTargeted:
            return .responderNotTargeted
        case .responderAlreadyResponded:
            return .responderAlreadyResponded
        case .offerNoLongerFunded:
            return .offerNoLongerFunded
        case .responderInsufficientResources:
            return .responderInsufficientResources
        }
    }
}

#if DEBUG
struct TradeAcceptEligibilityDiagnostic: Equatable {
    let reason: TradeAcceptEligibilityReason
    let stateRevision: Int?
    let hasActiveOffer: Bool
    let hasLocalActor: Bool

    var diagnosticValue: String {
        [
            "reason=\(reason.rawValue)",
            "rev=\(stateRevision.map(String.init) ?? "missing")",
            "offer=\(hasActiveOffer ? "present" : "missing")",
            "actor=\(hasLocalActor ? "known" : "missing")",
        ].joined(separator: ";")
    }
}

extension TradeAcceptEligibilityResolver {
    static func diagnostic(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> TradeAcceptEligibilityDiagnostic {
        TradeAcceptEligibilityDiagnostic(
            reason: resolve(state: state, actingAs: actingAs),
            stateRevision: state?.rev,
            hasActiveOffer: state?.activeTradeOffer != nil,
            hasLocalActor: actingAs != nil
        )
    }
}
#endif
