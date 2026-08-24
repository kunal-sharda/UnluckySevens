import SwiftUI

struct MessagesTranscriptBridgeView: View {
    let model: MessagesTranscriptBridgeModel
    let openGame: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            HStack(spacing: GameTheme.inlineSpacing) {
                Image(systemName: "die.face.5.fill")
                    .font(.title2)
                    .foregroundStyle(GameTheme.accent)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(model.title)
                        .font(GameTheme.headingFont)
                        .foregroundStyle(GameTheme.surface)
                        .lineLimit(1)

                    Text(model.status)
                        .font(GameTheme.metaFont.weight(.semibold))
                        .foregroundStyle(GameTheme.surface.opacity(0.78))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            Text(model.detail)
                .font(GameTheme.chipFont)
                .foregroundStyle(GameTheme.surface.opacity(0.68))
                .lineLimit(1)

            if model.canOpenGame {
                Button(action: openGame) {
                    Label("Open Game", systemImage: "arrow.up.right.square")
                        .font(GameTheme.metaFont.weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(GameTheme.accent)
                .foregroundStyle(GameTheme.ink)
                .accessibilityIdentifier("uls.transcript.openGame")
            }
        }
        .padding(GameTheme.shellPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GameTheme.feltRaised)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.transcript.bridge")
    }
}
