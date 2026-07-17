import SwiftUI

struct GamePhysicalDiceRollOverlayView: View {
    let result: GameDiceRollResult?
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var phase = GamePhysicalDiceRollPhase.rolling

    private var displayedResult: GameDiceRollResult {
        result ?? GameDiceRollResult(first: 1, second: 1)
    }

    var body: some View {
        Button(action: advanceAnimation) {
            ZStack {
                GamePhysicalTurnPalette.focusVeil
                    .opacity(result == nil ? 0 : 1)
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    Text(phase == .settled ? "\(displayedResult.first) + \(displayedResult.second) = \(displayedResult.total)" : "Rolling")
                        .font(GameTheme.displayFont)
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                        .contentTransition(.numericText())
                        .opacity(result == nil ? 0 : 1)

                    GameDiceBowlSceneView(
                        result: displayedResult,
                        isActive: result != nil,
                        isSettled: phase == .settled,
                        onAnimationFinished: finishRolling
                    )
                        .frame(maxWidth: 380)
                        .aspectRatio(1, contentMode: .fit)

                    Text(phase.instruction)
                        .font(.subheadline)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .opacity(result == nil ? 0 : 1)
                }
                .padding(.horizontal, 18)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .ignoresSafeArea()
        .opacity(result == nil ? 0.001 : 1)
        .allowsHitTesting(result != nil)
        .accessibilityHidden(result == nil)
        .accessibilityIdentifier("uls.startTurn.diceRoll")
        .accessibilityLabel(phase == .settled ? "Rolled \(displayedResult.first) and \(displayedResult.second)" : "Rolling dice")
        .accessibilityHint(phase.accessibilityHint)
        .task {
            if accessibilityReduceMotion {
                phase = .settled
            }
        }
        .onChange(of: result) { _, newValue in
            phase = newValue == nil || !accessibilityReduceMotion ? .rolling : .settled
        }
    }

    private func finishRolling() {
        guard phase == .rolling else { return }
        phase = .settled
    }

    private func advanceAnimation() {
        guard result != nil else { return }
        if phase == .settled {
            onComplete()
        } else {
            phase = .settled
        }
    }
}
