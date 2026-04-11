import ULS_CoreGame

enum GameBankTrayModelBuilder {
    static func build(
        state: CoreGameStateV1?,
        actingAs: String?,
        mode: GameMode,
        draft: GameDevCardDraft?
    ) -> GameBankTrayModel {
        guard let state else {
            return GameBankTrayModel(title: "Bank", subtitle: nil, chips: [])
        }

        let monopolyPreviews = Dictionary(
            uniqueKeysWithValues: state.monopolyPreviews(for: actingAs ?? "").map { ($0.resource, $0.claimCount) }
        )
        let yearOfPlentyOptions = Dictionary(
            uniqueKeysWithValues: state.yearOfPlentyBankOptions(for: actingAs ?? "").map { ($0.resource, $0.remainingCount) }
        )

        return GameBankTrayModel(
            title: "Bank",
            subtitle: subtitle(for: mode, draft: draft),
            chips: ResourceV1.tradeableCases.map { resource in
                let count = state.bankResources.count(for: resource)
                return GameBankChip(
                    resource: resource,
                    count: count,
                    detailText: detailText(
                        for: resource,
                        mode: mode,
                        draft: draft,
                        monopolyPreviews: monopolyPreviews
                    ),
                    isEnabled: isEnabled(
                        resource: resource,
                        count: count,
                        mode: mode,
                        draft: draft,
                        yearOfPlentyOptions: yearOfPlentyOptions
                    ),
                    isSelected: isSelected(resource: resource, draft: draft),
                    selectionIndex: selectionIndex(resource: resource, draft: draft)
                )
            }
        )
    }

    private static func subtitle(for mode: GameMode, draft: GameDevCardDraft?) -> String? {
        switch mode {
        case .devCardMonopoly:
            return "Choose the resource to claim from every opponent."
        case .devCardYearOfPlenty:
            guard let draft else {
                return "Choose two resources from the bank."
            }
            switch draft {
            case let .yearOfPlenty(first, second):
                if first == nil {
                    return "Choose the first resource."
                }
                if second == nil {
                    return "Choose the second resource."
                }
                return "Confirm the selected pair."
            default:
                return "Choose two resources from the bank."
            }
        default:
            return nil
        }
    }

    private static func detailText(
        for resource: ResourceV1,
        mode: GameMode,
        draft: GameDevCardDraft?,
        monopolyPreviews: [ResourceV1: Int]
    ) -> String? {
        switch mode {
        case .devCardMonopoly:
            return "Claim \(monopolyPreviews[resource] ?? 0)"
        case .devCardYearOfPlenty:
            if let selectionIndex = selectionIndex(resource: resource, draft: draft) {
                return selectionIndex == 1 ? "First pick" : "Second pick"
            }
            return nil
        default:
            return nil
        }
    }

    private static func isEnabled(
        resource: ResourceV1,
        count: Int,
        mode: GameMode,
        draft: GameDevCardDraft?,
        yearOfPlentyOptions: [ResourceV1: Int]
    ) -> Bool {
        switch mode {
        case .devCardMonopoly:
            return true
        case .devCardYearOfPlenty:
            guard yearOfPlentyOptions[resource] != nil else {
                return false
            }
            guard let draft else {
                return count > 0
            }
            switch draft {
            case let .yearOfPlenty(first, second):
                if second != nil {
                    return true
                }
                if let first, first == resource {
                    return count >= 2
                }
                return count > 0
            default:
                return false
            }
        default:
            return false
        }
    }

    private static func isSelected(resource: ResourceV1, draft: GameDevCardDraft?) -> Bool {
        selectionIndex(resource: resource, draft: draft) != nil
    }

    private static func selectionIndex(resource: ResourceV1, draft: GameDevCardDraft?) -> Int? {
        guard let draft else {
            return nil
        }

        switch draft {
        case let .monopoly(selected):
            return selected == resource ? 1 : nil
        case let .yearOfPlenty(first, second):
            if first == resource {
                return 1
            }
            if second == resource {
                return 2
            }
            return nil
        default:
            return nil
        }
    }
}

private extension ResourceV1 {
    static var tradeableCases: [ResourceV1] {
        [.wood, .brick, .sheep, .wheat, .ore]
    }
}
