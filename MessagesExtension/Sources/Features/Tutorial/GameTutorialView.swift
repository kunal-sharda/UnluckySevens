import SwiftUI

struct GameTutorialView: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let preferences: AppPreferences
    let onDismiss: () -> Void
    @State private var stepIndex = 0
    @State private var showsNavigationCoach = true

    private var steps: [GameTutorialStep] { GameTutorialStep.all }
    private var step: GameTutorialStep { steps[stepIndex] }
    private var motionPolicy: GameMotionPolicy {
        GameMotionPolicy(
            skipsAnimations: preferences.skipsAnimations,
            reducesMotion: accessibilityReduceMotion
        )
    }

    var body: some View {
        ZStack {
            GameTutorialPreviewView(
                step: step,
                usesAccessibleCalloutList: dynamicTypeSize.isAccessibilitySize,
                showsCoachMarks: !showsNavigationCoach,
                preferences: preferences
            )
            .overlayPreferenceValue(GameTutorialTargetPreferenceKey.self) { anchors in
                if isTradeStep, let closeAnchor = anchors[.tradeClose] {
                    GeometryReader { geometry in
                        let closeFrame = geometry[closeAnchor]
                        Button(action: onDismiss) {
                            Color.clear
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .position(x: closeFrame.midX, y: closeFrame.midY)
                        .accessibilityLabel("Exit tutorial")
                        .accessibilityIdentifier("uls.tutorial.exit")
                    }
                }
            }
            .id(step.id)
            .transition(stepTransition)
            .zIndex(isTradeStep ? 2 : 0)

            tapNavigationZones
                .allowsHitTesting(!showsNavigationCoach)
                .accessibilityHidden(showsNavigationCoach)
                .zIndex(1)

            if showsNavigationCoach {
                navigationCoachVeil
                    .transition(.opacity)
                    .zIndex(20)
            }
        }
        .overlay(alignment: .topLeading) {
            if !showsNavigationCoach, !isTradeStep {
                exitButton
                    .padding(GameTheme.shellPadding)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
        }
        .overlay(alignment: .top) {
            if !showsNavigationCoach, !isTradeStep {
                tutorialProgressAccessibilityMarker
            }
        }
        .background(GameTheme.appBackground.ignoresSafeArea())
    }

    private var tapNavigationZones: some View {
        HStack(spacing: 0) {
            Button {
                move(to: stepIndex - 1)
            } label: {
                Color.clear
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .disabled(stepIndex == 0)
            .accessibilityLabel("Previous tutorial step")
            .accessibilityHint("Moves to the previous tutorial instruction")
            .accessibilityIdentifier("uls.tutorial.back")

            Button {
                if stepIndex == steps.count - 1 {
                    onDismiss()
                } else {
                    move(to: stepIndex + 1)
                }
            } label: {
                Color.clear
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(stepIndex == steps.count - 1 ? "Finish tutorial" : "Next tutorial step")
            .accessibilityHint(
                stepIndex == steps.count - 1
                    ? "Closes the tutorial"
                    : "Moves to the next tutorial instruction"
            )
            .accessibilityIdentifier(
                stepIndex == steps.count - 1 ? "uls.tutorial.done" : "uls.tutorial.next"
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }

    private var exitButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(GameTheme.surface)
                .frame(width: 44, height: 44)
                .background(GameTheme.felt, in: Circle())
                .overlay {
                    Circle()
                        .stroke(GameTheme.accent.opacity(0.72), lineWidth: 1.5)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Exit tutorial")
        .accessibilityIdentifier("uls.tutorial.exit")
    }

    private var tutorialProgressAccessibilityMarker: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(step.title)
            .accessibilityValue("Tutorial")
            .accessibilityHint(step.guidance)
            .accessibilityIdentifier("uls.tutorial.progress")
    }

    private var isTradeStep: Bool {
        switch step.id {
        case .playerTrade, .tradeRecipients, .bankTrade:
            true
        default:
            false
        }
    }

    private var navigationCoachVeil: some View {
        Button {
            withAnimation(motionPolicy.resolvedAnimation()) {
                showsNavigationCoach = false
            }
        } label: {
            ZStack {
                Color.black.opacity(0.64)
                    .ignoresSafeArea()

                HStack(spacing: 0) {
                    navigationCoachHalf(
                        title: "Tap left side",
                        subtitle: "Back",
                        systemImage: "arrow.left"
                    )

                    Rectangle()
                        .fill(GameTheme.surface.opacity(0.42))
                        .frame(width: 1, height: 210)

                    navigationCoachHalf(
                        title: "Tap right side",
                        subtitle: "Next",
                        systemImage: "arrow.right"
                    )
                }
                .padding(.horizontal, 18)

                Text("Tap once to start")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.surface.opacity(0.82))
                    .offset(y: 104)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityLabel("Tutorial navigation")
        .accessibilityHint("Tap once to begin. Then tap the left side for back or the right side for next.")
        .accessibilityIdentifier("uls.tutorial.navigationCoach")
    }

    private func navigationCoachHalf(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .bold))
            Text(title)
                .font(GameTheme.headingFont)
            Text(subtitle)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.accent)
        }
        .foregroundStyle(GameTheme.surface)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    private var stepTransition: AnyTransition {
        motionPolicy.animatesSpatialMotion ? .opacity.combined(with: .scale(scale: 0.995)) : .opacity
    }

    private func move(to index: Int) {
        guard steps.indices.contains(index) else { return }
        withAnimation(motionPolicy.resolvedAnimation()) {
            stepIndex = index
        }
    }
}
