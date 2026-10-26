/// Presentation-only routing. Canonical eligibility is supplied by the view model.
struct GameLifecycleActionPresentation {
    enum Action: Equatable {
        case claimVictory, resendUpdate, proposeDraw, agreeDraw, declineDraw, resign, hostEnd
    }

    enum Screen: Equatable {
        case actions, resign, hostEnd, proposeDraw
    }

    struct Availability: Equatable {
        var claimVictory = false
        var resendUpdate = false
        var proposeDraw = false
        var voteOnDraw = false
        var resign = false
        var hostEnd = false

        func allows(_ action: Action) -> Bool {
            if action == .resendUpdate { return resendUpdate }
            if action == .claimVictory { return claimVictory }
            guard !claimVictory else { return false }
            switch action {
            case .proposeDraw: return proposeDraw && !voteOnDraw
            case .agreeDraw, .declineDraw: return voteOnDraw
            case .resign: return resign
            case .hostEnd: return hostEnd
            case .claimVictory, .resendUpdate: return false
            }
        }
    }

    private(set) var screen: Screen = .actions

    mutating func select(_ action: Action, availability: Availability) -> Action? {
        guard availability.allows(action) else { return nil }
        switch action {
        case .resign: screen = .resign
        case .hostEnd: screen = .hostEnd
        case .proposeDraw: screen = .proposeDraw
        default: return action
        }
        return nil
    }

    mutating func cancel() { screen = .actions }

    mutating func confirm(availability: Availability) -> Action? {
        let action: Action
        switch screen {
        case .actions: return nil
        case .resign: action = .resign
        case .hostEnd: action = .hostEnd
        case .proposeDraw: action = .proposeDraw
        }
        screen = .actions
        return availability.allows(action) ? action : nil
    }
}
