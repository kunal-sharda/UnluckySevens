import SwiftUI

struct CompactLaunchView: View {
    let skipsAnimations: Bool
    let openLobby: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isLanded = false
    @State private var isPlacementInProgress = true

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Spacer(minLength: 12)

                ZStack(alignment: .top) {
                    Button(
                        "Open Lobby",
                        systemImage: "person.3.fill",
                        action: openLobby
                    )
                    .buttonStyle(CompactLaunchButtonStyle())
                    .accessibilityHint("Opens a fresh invitation lobby")
                    .accessibilityIdentifier("uls.compactLaunch.openLobby")
                    .padding(.top, 62)

                    RobberIdentityMark()
                        .frame(width: 64, height: 104)
                        .scaleEffect(isVisuallyLanded ? 1 : 0.84)
                        .rotationEffect(.degrees(isVisuallyLanded ? 0 : -12))
                        .offset(y: isVisuallyLanded ? 0 : -180)
                        .allowsHitTesting(false)
                }
                .frame(height: 158)

                Spacer(minLength: 12)
            }
            .padding(.horizontal, GameTheme.shellPadding)

            if showsSkip {
                Button("Skip", action: settleImmediately)
                    .font(GameTheme.metaFont.bold())
                    .foregroundStyle(GameTheme.surface)
                    .frame(minWidth: 60, minHeight: 44)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .accessibilityHint("Finishes the robber placement animation")
                    .accessibilityIdentifier("uls.compactLaunch.skip")
                    .padding(.trailing, GameTheme.shellPadding)
                    .transition(.opacity)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.compactLaunch")
        .accessibilityLabel("Unlucky Sevens compact launch")
        .accessibilityValue(accessibilityPlacementValue)
        .onAppear(perform: beginPlacement)
        .onChange(of: reduceMotion) { _, _ in
            if !motionPolicy.animatesSpatialMotion {
                settleImmediately()
            }
        }
        .onChange(of: skipsAnimations) { _, _ in
            if !motionPolicy.animatesSpatialMotion {
                settleImmediately()
            }
        }
    }

    private var motionPolicy: GameMotionPolicy {
        GameMotionPolicy(
            skipsAnimations: skipsAnimations,
            reducesMotion: reduceMotion
        )
    }

    private var isVisuallyLanded: Bool {
        !motionPolicy.animatesSpatialMotion || isLanded
    }

    private var showsSkip: Bool {
        motionPolicy.animatesSpatialMotion && isPlacementInProgress
    }

    private var accessibilityPlacementValue: String {
        showsSkip ? "placing" : "landed"
    }

    private func beginPlacement() {
        guard motionPolicy.animatesSpatialMotion else {
            settleImmediately()
            return
        }

        isPlacementInProgress = true
        isLanded = false
        withAnimation(.spring(duration: 0.8, bounce: 0.24)) {
            isLanded = true
        } completion: {
            isPlacementInProgress = false
        }
    }

    private func settleImmediately() {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isLanded = true
            isPlacementInProgress = false
        }
    }
}
