import SwiftUI
import ULS_CoreGame

/// Read-only help presented over the still-mounted lobby or game.
struct GameLearningView: View {
    let preferences: AppPreferences
    let isInGame: Bool
    let boardStrategy: BoardGenStrategyV1
    let onDismiss: () -> Void
    var ownedDevPanel: GameDevCardPanelModel? = nil
    var receipt: ProductionReceiptV1? = nil
    var rollerName = ""
    var unavailableReceiptText: String? = nil

    private enum Destination: Hashable {
        case controls
        case beginner
        case strategy
    }

    @State private var path: [Destination] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(isInGame ? "Standard Catan · 10 points to win" : "Standard Catan reference · 10 points to win")
                        .font(.subheadline)
                    Text(boardStrategy == .noRedAdjacentV1 ? "Balanced board" : "Classic random board")
                        .font(.caption)
                    NavigationLink(value: Destination.controls) {
                            HStack { Text("Know Catan? Learn the Controls"); Spacer(); Image(systemName: "chevron.right").accessibilityHidden(true) }
                        }
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("uls.learning.controls")
                    NavigationLink(value: Destination.beginner) {
                            HStack { Text("New to Catan? Learn the Game"); Spacer(); Image(systemName: "chevron.right").accessibilityHidden(true) }
                        }
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("uls.learning.beginner")
                    NavigationLink(value: Destination.strategy) {
                            HStack { Text("Strategy quick tips"); Spacer(); Image(systemName: "chevron.right").accessibilityHidden(true) }
                        }
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("uls.learning.strategy")
                    if let ownedDevPanel {
                        DisclosureGroup("Your owned Dev Cards") {
                            GameOwnedDevInspectionView(panel: ownedDevPanel, allowsPlaying: false, onPlay: { _ in })
                                .frame(height: 280)
                            Text("Close Reference to play an eligible card from Hand. Inspecting here never plays a card.").font(.caption)
                        }
                    }
                    if let receipt {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your latest observed roll").font(.headline)
                            GameRollReceiptView(receipt: receipt, rollerName: rollerName)
                        }
                    }
                    if let unavailableReceiptText {
                        Text(unavailableReceiptText).font(.subheadline)
                    }
                    Divider()
                    GameQuickReferenceContent()
                }
                .disclosureGroupStyle(GameReferenceDisclosureStyle())
                .buttonStyle(.plain)
                .font(.body)
                .padding(20)
            }
            .background(GameTheme.surface.ignoresSafeArea())
            .foregroundStyle(GameTheme.felt)
            .navigationTitle("Learn & Reference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close", action: onDismiss)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("uls.learning.close")
                }
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .controls:
                    GameControlsTourView(preferences: preferences) { path.removeLast() }
                case .beginner:
                    GameTutorialView(preferences: preferences) { path.removeLast() }
                case .strategy:
                    GameTutorialStrategyCardView(onDismiss: { path.removeLast() })
                }
            }
        }
        .tint(GameTheme.felt)
        .accessibilityIdentifier("uls.learning.surface")
    }
}

struct GameQuickReferenceContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            section("Costs") {
                cost("Road", hand: CoreBuildCostsV1.road)
                cost("Settlement · 1 VP", hand: CoreBuildCostsV1.settlement)
                cost("City · 2 VP", hand: CoreBuildCostsV1.city)
                cost("Development Card", hand: CoreBuildCostsV1.developmentCard)
            }
            section("Your turn") {
                Text("Roll, then trade and build in any order. End Turn hands play to the next player.")
                Text("An eligible Development Card can be played before or after rolling.")
            }
            section("Development Cards") {
                Text("Tap the public Dev pile to inspect the cost and confirm a purchase. Find owned cards in Hand → Dev Cards.")
                Text("Play at most one action card per turn. A card bought this turn waits until a later turn. Victory Points count immediately, even when bought this turn, and reveal automatically at 10 points on your turn.")
            }
            section("Scoring") {
                Text("Settlement 1 · City 2 · Longest Road 2 · Largest Army 2. Public scores exclude hidden Victory Point cards. Reach 10 points on your turn to win.")
            }
            DisclosureGroup("Setup and placement") {
                Text("Place a settlement and connected road twice, reversing player order for the second round. Your second settlement grants adjacent resources. Keep settlements at least two edges apart. Later roads connect to your network, and a city replaces your settlement.")
                    .padding(.vertical, 8)
            }
            DisclosureGroup("Seven, discard and robber") {
                Text("A seven produces no resources. Players holding more than seven resource cards discard half, rounded down. The roller moves the robber to another tile and steals a random resource from an eligible adjacent player. The robber blocks production on its tile.")
                    .padding(.vertical, 8)
            }
            DisclosureGroup("Trading and Bank supply") {
                Text("Trade with other players during your turn, or exchange matching resources with the Bank. The normal ratio is 4:1. A general port gives 3:1 and a matching resource port gives 2:1.")
                    .padding(.top, 8)
                Text("Tap Bank to inspect approximate supply. More filled segments means more cards. An empty bar means none. Opening Trade shows these bars automatically.")
                    .padding(.bottom, 8)
            }
            DisclosureGroup("Production and awards") {
                Text("When a number rolls, adjacent settlements produce one resource and cities produce two, unless the robber blocks the tile. A Bank shortage can prevent a payout.")
                    .padding(.top, 8)
                Text("Longest Road starts at five connected roads. Largest Army starts at three played Knights. A challenger needs a larger total to take an award from its owner.")
                    .padding(.bottom, 8)
            }
        }
        .font(.body)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func cost(_ name: String, hand: ResourceHandV1) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.subheadline.bold())
            GameBuildCostRow(cost: hand)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Make the whole wrapped label actionable, including at accessibility text sizes.
struct GameReferenceDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { configuration.isExpanded.toggle() } label: {
                HStack {
                    configuration.label
                    Spacer(minLength: 8)
                    Image(systemName: configuration.isExpanded ? "chevron.down" : "chevron.right")
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .accessibilityValue(configuration.isExpanded ? "Expanded" : "Collapsed")
            if configuration.isExpanded { configuration.content }
        }
    }
}
