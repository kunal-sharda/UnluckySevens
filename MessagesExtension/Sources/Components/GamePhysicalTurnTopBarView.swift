import SwiftUI

struct GamePhysicalTurnTopBarView: View {
    let title: String
    let subtitle: String
    var prompt: GamePhysicalTurnHeaderPrompt? = nil
    let isGameInfoOpen: Bool
    let onSettingsTap: () -> Void
    let onGamesTap: () -> Void
    let onGameInfoTap: () -> Void

    init(
        title: String,
        subtitle: String,
        prompt: GamePhysicalTurnHeaderPrompt? = nil,
        isGameInfoOpen: Bool,
        onSettingsTap: @escaping () -> Void,
        onGamesTap: @escaping () -> Void,
        onGameInfoTap: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.prompt = prompt
        self.isGameInfoOpen = isGameInfoOpen
        self.onSettingsTap = onSettingsTap
        self.onGamesTap = onGamesTap
        self.onGameInfoTap = onGameInfoTap
    }

    var body: some View {
        HStack(spacing: 8) {
            iconButton(
                title: "Games",
                systemImage: "square.stack.3d.up.fill",
                isSelected: false,
                action: onGamesTap
            )
            .accessibilityIdentifier("uls.game.games")

            iconButton(
                title: "Settings",
                systemImage: "gearshape.fill",
                isSelected: false,
                action: onSettingsTap
            )

            HStack(spacing: 7) {
                if let prompt {
                    GamePhysicalTurnPromptView(text: prompt.text)
                } else if title != "Your turn" {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .multilineTextAlignment(.center)
                } else if rollValues.count >= 2 {
                    HStack(spacing: 3) {
                        die(rollValues[0])
                        die(rollValues[1])
                    }

                    Text("= \(rollValues.last ?? 0)")
                        .font(.subheadline.bold())
                        .monospacedDigit()
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                } else {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(prompt?.text ?? "\(title), \(subtitle)")
            .accessibilityIdentifier("uls.turn.status")

            iconButton(
                title: "Players and game information",
                systemImage: "person.2.fill",
                isSelected: isGameInfoOpen,
                action: onGameInfoTap
            )
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.turn.topBar")
    }

    private func iconButton(
        title: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, systemImage: systemImage, action: action)
            .labelStyle(.iconOnly)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(GamePhysicalTurnPalette.primaryText)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .buttonStyle(.plain)
            .overlay {
                if isSelected {
                    Circle()
                        .stroke(GamePhysicalTurnPalette.selectedKeyline, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                }
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var rollValues: [Int] {
        subtitle
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }
    }

    private func die(_ value: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(GamePhysicalTurnPalette.primaryText)

            ForEach(Array(GameDiePipLayout.positions(for: value).enumerated()), id: \.offset) { _, position in
                Circle()
                    .fill(GamePhysicalTurnPalette.cardCountInk)
                    .frame(width: 3.5, height: 3.5)
                    .position(x: position.x * 23, y: position.y * 23)
            }
        }
        .frame(width: 23, height: 23)
        .overlay {
            RoundedRectangle(cornerRadius: 5)
                .stroke(.black.opacity(0.30), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

struct GamePhysicalTurnPromptView: View {
    let text: String

    var body: some View {
        VStack(spacing: 4) {
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .multilineTextAlignment(.center)

            Capsule()
                .fill(GamePhysicalTurnPalette.selectedKeyline)
                .frame(width: 22, height: 2)
        }
    }
}
