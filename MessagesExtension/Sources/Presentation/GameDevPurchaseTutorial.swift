import ULS_CoreGame

/// Detects only the local purchase just submitted, never cards arriving via a remote update.
enum GameDevPurchaseTutorial {
    static func newKind(before: GameDevCardPanelModel?, after: GameDevCardPanelModel?) -> GameDevCardVisualKind? {
        guard let before, let after else { return nil }
        let increases = GameDevCardVisualKind.allCases.filter { kind in
            let old = before.newCounts.first { $0.title == kind.title }?.count ?? 0
            let new = after.newCounts.first { $0.title == kind.title }?.count ?? 0
            return new != old
        }
        guard increases.count == 1, let kind = increases.first else { return nil }
        let old = before.newCounts.first { $0.title == kind.title }?.count ?? 0
        let new = after.newCounts.first { $0.title == kind.title }?.count ?? 0
        return new == old + 1 ? kind : nil
    }
}
