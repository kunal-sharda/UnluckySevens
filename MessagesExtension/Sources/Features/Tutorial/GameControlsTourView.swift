import SwiftUI

struct GameControlsTourView: View {
    let preferences: AppPreferences
    let onDismiss: () -> Void

    @State private var progress: GameControlsTourProgress
    @State private var showsReference = false

    init(preferences: AppPreferences, onDismiss: @escaping () -> Void) {
        self.preferences = preferences
        self.onDismiss = onDismiss
        _progress = State(initialValue: preferences.controlsTourProgress)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if progress.index < GameControlInteraction.allCases.count {
                    let interaction = GameControlInteraction.allCases[progress.index]
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(instruction(for: interaction)).font(.subheadline)
                                .accessibilityAddTraits(.isHeader)
                            HStack {
                                Button("Back") { progress.back() }.disabled(progress.index == 0)
                                Spacer()
                                Button("Reference") { showsReference = true }
                                Spacer()
                                if progress.completed.contains(interaction) {
                                    Button("Continue") { progress.advance() }
                                        .accessibilityIdentifier("uls.controls.continue")
                                } else {
                                    Button("Skip") { progress.advance() }
                                        .accessibilityIdentifier("uls.controls.skip")
                                }
                            }
                            .frame(minHeight: 44)
                        }
                        .padding(12)
                    }
                    .frame(height: min(150, geometry.size.height * 0.28))
                    .foregroundStyle(GameTheme.felt)
                    .background(GameTheme.surface)
                    GameControlsPracticeView(interaction: interaction, skipsAnimations: preferences.skipsAnimations,
                                             onReference: { showsReference = true }) { event in
                        progress.record(event)
                    }
                    .id(progress.index)
                    .frame(width: geometry.size.width, height: max(0, geometry.size.height - min(150, geometry.size.height * 0.28)))
                } else {
                    VStack(spacing: 20) {
                        Text(progress.isComplete ? "Controls practiced" : "Practice saved")
                            .font(.title2).accessibilityAddTraits(.isHeader)
                        Text("\(progress.completed.count) of \(GameControlInteraction.allCases.count) controls practiced.")
                        Text("In Messages, open the latest game bubble to resume. Read the turn prompt to see who acts next. Settings and Players hold the current game’s options.")
                        Button("Replay") { progress = GameControlsTourProgress() }
                        Button("Return to Reference", action: onDismiss)
                    }
                    .padding(24)
                    .foregroundStyle(GameTheme.surface)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(GameTheme.felt)
        .navigationTitle("Learn the Controls")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Exit", action: onDismiss)
            }
        }
        .onChange(of: progress) { _, value in preferences.controlsTourProgress = value }
        .sheet(isPresented: $showsReference) {
            NavigationStack {
                ScrollView { GameQuickReferenceContent().padding(20) }
                    .background(GameTheme.surface)
                    .foregroundStyle(GameTheme.felt)
                    .toolbar { Button("Done") { showsReference = false } }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.controls.surface")
    }

    private func instruction(for interaction: GameControlInteraction) -> String {
        switch interaction {
        case .bank: "Know Catan? Practice the controls here. In Messages, open the latest game bubble and read whose turn it is. Tap Bank to inspect supply."
        case .publicDev: "Tap the public Dev pile to inspect a purchase. Buying requires a separate confirmation."
        case .hand: "Tap Hand to open or tuck away your private cards."
        case .boardConfirmed: "Open Build, choose Road, select a highlighted edge, then confirm the placement. Only this practice table changes."
        case .trade: "Open Trade to see player and Bank exchanges. Supply appears automatically."
        case .ownedDev: "Open Hand → Dev Cards. Inspect the card labels for what can be played now and what must wait."
        case .players: "Open Players to see identities, public scores and current-game actions."
        case .endTurn: "Choose End Turn, then confirm. This hands the practice turn to the next player."
        }
    }
}

private struct GameControlsPracticeView: View {
    let interaction: GameControlInteraction
    let onInteraction: (GameControlInteraction) -> Void
    let onReference: () -> Void
    @State private var showsSettings = false
    @State private var showsPlayerRecordExplanation = false
    @StateObject private var session: GameControlsPracticeSession

    init(interaction: GameControlInteraction, skipsAnimations: Bool,
         onReference: @escaping () -> Void,
         onInteraction: @escaping (GameControlInteraction) -> Void) {
        self.interaction = interaction
        self.onInteraction = onInteraction
        self.onReference = onReference
        _session = StateObject(wrappedValue: GameControlsPracticeSession(skipsAnimations: skipsAnimations))
    }

    var body: some View {
        GameShellView(viewModel: session.model, onSettingsTap: { showsSettings = true },
                      onReferenceTap: onReference,
                      onGamesTap: { showsPlayerRecordExplanation = true },
                      preferences: session.preferences,
                      isUtilityPresented: showsSettings,
                      isSyntheticSession: true,
                      onControlInteraction: onInteraction)
            .overlay {
                if showsSettings {
                    AppSettingsView(preferences: session.preferences, summary: GameSettingsSummary(),
                                    onDismiss: { showsSettings = false })
                }
            }
            .alert("Player Record", isPresented: $showsPlayerRecordExplanation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your real game’s Players panel opens your saved game history. Practice games stay here.")
            }
    }
}
