struct GameTurnObjectRailSlot: Identifiable, Equatable {
    enum Kind: String, CaseIterable, Identifiable {
        case hand
        case build
        case trade
        case devCards
        case endTurn

        var id: String { rawValue }
    }

    let kind: Kind
    let actionItem: GameActionDockItem?

    var id: Kind { kind }
    var isAvailable: Bool { kind == .hand || actionItem != nil }
}

struct GameTurnObjectRailModel: Equatable {
    let slots: [GameTurnObjectRailSlot]

    static func build(actionDock: GameActionDockModel) -> GameTurnObjectRailModel {
        let itemsByKind = Dictionary(
            uniqueKeysWithValues: actionDock.primaryItems
                .filter(\.isEnabled)
                .map { ($0.kind, $0) }
        )

        return GameTurnObjectRailModel(
            slots: GameTurnObjectRailSlot.Kind.allCases.map { kind in
                GameTurnObjectRailSlot(
                    kind: kind,
                    actionItem: actionKind(for: kind).flatMap { itemsByKind[$0] }
                )
            }
        )
    }

    private static func actionKind(
        for kind: GameTurnObjectRailSlot.Kind
    ) -> GameActionDockItem.Kind? {
        switch kind {
        case .hand: return nil
        case .build: return .build
        case .trade: return .trade
        case .devCards: return .devCards
        case .endTurn: return .endTurn
        }
    }
}
