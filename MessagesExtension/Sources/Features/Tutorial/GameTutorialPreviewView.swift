import SwiftUI
import ULS_CoreGame

struct GameTutorialPreviewView: View {
    let step: GameTutorialStep
    let usesAccessibleCalloutList: Bool
    let showsCoachMarks: Bool
    let preferences: AppPreferences

    @StateObject private var tutorialViewModel: LobbyDriverViewModel

    init(
        step: GameTutorialStep,
        usesAccessibleCalloutList: Bool,
        showsCoachMarks: Bool,
        preferences: AppPreferences
    ) {
        self.step = step
        self.usesAccessibleCalloutList = usesAccessibleCalloutList
        self.showsCoachMarks = showsCoachMarks
        self.preferences = preferences
        _tutorialViewModel = StateObject(
            wrappedValue: LobbyDriverViewModel(
                tutorialState: GameTutorialStateComposer.state(for: step.id),
                tutorialActorID: GameTutorialStateComposer.localPlayer
            )
        )
    }

    var body: some View {
        ZStack {
            configuredProductionGameSurface
                .overlayPreferenceValue(GameTutorialTargetPreferenceKey.self) { anchors in
                    if showsCoachMarks, !usesAccessibleCalloutList {
                        GameTutorialCoachOverlayView(
                            callouts: step.callouts,
                            anchors: anchors
                        )
                    }
                }

            if showsCoachMarks {
                if usesAccessibleCalloutList {
                    accessibleCoachMarks
                }
            }
        }
    }

    @ViewBuilder
    private var configuredProductionGameSurface: some View {
#if DEBUG
        productionGameSurface
            .dynamicTypeSize(.large)
            .allowsHitTesting(false)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("uls.tutorial.preview")
#else
        productionGameSurface
            .dynamicTypeSize(.large)
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(step.previewAccessibilityLabel)
            .accessibilityIdentifier("uls.tutorial.preview")
#endif
    }

    @ViewBuilder
    private var productionGameSurface: some View {
        GameShellView(
            viewModel: tutorialViewModel,
            preferences: preferences,
            initialMode: initialMode,
            initialRoute: initialRoute,
            minimumActionSurfaceHeight: minimumActionSurfaceHeight,
            tutorialTradeTarget: tutorialTradeTarget,
            tutorialHeaderTitle: isTradeStep ? "Trade" : nil
        )
    }

    private var accessibleCoachMarks: some View {
        VStack(alignment: .leading, spacing: 6) {
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(GameTheme.headingFont)
                    .accessibilityAddTraits(.isHeader)
                Text(step.guidance)
                    .font(GameTheme.metaFont)
            }
            .foregroundStyle(GameTheme.surface)
            .padding(10)
            .frame(maxWidth: 260, alignment: .leading)
            .background(GameTheme.felt.opacity(0.97), in: RoundedRectangle(cornerRadius: 9))

            ForEach(step.callouts) { coachMark($0) }
        }
        .padding(.horizontal, GameTheme.shellPadding)
        .padding(.bottom, 66)
        .allowsHitTesting(false)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityIdentifier("uls.tutorial.accessibleGuide")
    }

    private func coachMark(_ callout: GameTutorialCallout) -> some View {
        HStack(spacing: 7) {
            Text("\(callout.number)")
                .font(.caption.bold())
                .foregroundStyle(GameTheme.accent)

            Text(callout.text)
                .font(GameTheme.chipFont)
                .foregroundStyle(GameTheme.ink)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: 184, alignment: .leading)
        .background(GameTheme.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(GameTheme.accent, lineWidth: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Callout \(callout.number). \(callout.text)")
    }

    private var initialMode: GameMode {
        switch step.id {
        case .setupSettlement, .setupRoad: .setup
        case .legalPlacement: .buildSettlement
        case .playerTrade, .tradeRecipients, .bankTrade: .trade
        case .discard: .discard
        case .moveRobber: .robberMove
        case .chooseVictim: .robberVictim
        case .developmentCards: .playDevCard
        case .rollDice,
             .readProduction,
             .useHand,
             .buildCosts,
             .endTurn,
             .strategy,
             .victoryAwards: .idle
        }
    }

    private var initialRoute: GameShellRoute {
        switch step.id {
        case .buildCosts, .legalPlacement:
            .build
        case .playerTrade:
            .trade(
                .playerDraft(
                    GameTradeDraft(
                        kind: .offer,
                        give: ResourceHandV1(wood: 2),
                        receive: ResourceHandV1(brick: 1),
                        recipients: []
                    )
                )
            )
        case .tradeRecipients:
            .trade(
                .playerDraft(
                    GameTradeDraft(
                        kind: .offer,
                        give: ResourceHandV1(wood: 2),
                        receive: ResourceHandV1(brick: 1),
                        recipients: ["tutorial-maya"]
                    )
                )
            )
        case .bankTrade:
            .trade(.maritime)
        case .developmentCards:
            .devCards
        case .endTurn:
            .endTurnConfirmation
        case .victoryAwards:
            .gameInfo
        case .setupSettlement,
             .setupRoad,
             .rollDice,
             .readProduction,
             .useHand,
             .discard,
             .moveRobber,
             .chooseVictim,
             .strategy:
            .none
        }
    }

    private var minimumActionSurfaceHeight: CGFloat? {
        switch step.id {
        case .victoryAwards:
            224
        default:
            nil
        }
    }

    private var tutorialTradeTarget: GameTutorialTarget? {
        step.id == .tradeRecipients ? .tradeRecipients : nil
    }

    private var isTradeStep: Bool {
        switch step.id {
        case .playerTrade, .tradeRecipients, .bankTrade:
            true
        default:
            false
        }
    }
}
