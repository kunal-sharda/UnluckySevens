import SwiftUI

struct GameControlsTourView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
            let instructionHeight = dynamicTypeSize.isAccessibilitySize
                ? min(260, geometry.size.height * 0.42)
                : min(110, geometry.size.height * 0.24)
            VStack(spacing: 0) {
                if progress.index < GameControlInteraction.allCases.count {
                    let interaction = GameControlInteraction.allCases[progress.index]
                    VStack(alignment: .leading, spacing: 4) {
                            ScrollView {
                                Text(instruction(for: interaction)).font(.subheadline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .accessibilityAddTraits(.isHeader)
                            }
                            HStack {
                                Button { progress.back() } label: { Text("Back").frame(minWidth: 44, minHeight: 44).contentShape(Rectangle()) }.disabled(progress.index == 0)
                                Spacer()
                                Button { showsReference = true } label: { Text("Reference").frame(minHeight: 44).contentShape(Rectangle()) }
                                Spacer()
                                if progress.completed.contains(interaction) {
                                    Button { progress.advance() } label: { Text("Continue").frame(minHeight: 44).contentShape(Rectangle()) }
                                        .accessibilityIdentifier("uls.controls.continue")
                                } else {
                                    Button { progress.advance() } label: { Text("Skip").frame(minWidth: 44, minHeight: 44).contentShape(Rectangle()) }
                                        .accessibilityIdentifier("uls.controls.skip")
                                }
                            }
                            .font(.subheadline)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(minHeight: 44)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(height: instructionHeight)
                    .foregroundStyle(GameTheme.felt)
                    .background(GameTheme.surface)
                    GameControlsPracticeView(interaction: interaction, skipsAnimations: preferences.skipsAnimations,
                                             onReference: { showsReference = true }) { event in
                        progress.record(event)
                    }
                    .id(progress.index)
                    .frame(width: geometry.size.width, height: max(0, geometry.size.height - instructionHeight))
                } else {
                    VStack(spacing: 20) {
                        Text(progress.isComplete ? "Controls practiced" : "Practice saved")
                            .font(.title2).accessibilityAddTraits(.isHeader)
                        Text("\(progress.completed.count) of \(GameControlInteraction.allCases.count) controls practiced.")
                        Text("In Messages, open the latest game bubble to resume. Read the turn prompt to see who acts next. Settings and Players hold the current game’s options.")
                        Button { progress = GameControlsTourProgress() } label: { Text("Replay").frame(minHeight: 44).contentShape(Rectangle()) }
                        Button(action: onDismiss) { Text("Return to Reference").frame(minHeight: 44).contentShape(Rectangle()) }
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
        case .bank: "Tap Bank to inspect approximate supply. This is a practice game."
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
