import SwiftUI

struct PlayerRecordHeaderView: View {
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            Text("Player Record")
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.surface)
                .accessibilityAddTraits(.isHeader)

            HStack {
                Button("Back", systemImage: "chevron.left", action: dismiss)
                    .font(GameTheme.metaFont.bold())
                    .frame(minWidth: 84, minHeight: 44, alignment: .leading)
                Spacer()
                Color.clear
                    .frame(width: 84, height: 44)
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(GameTheme.surface)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, GameTheme.shellPadding)
        .padding(.vertical, GameTheme.inlineSpacing)
    }
}
