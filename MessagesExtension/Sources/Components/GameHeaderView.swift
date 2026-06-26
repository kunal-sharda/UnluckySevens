import SwiftUI

struct GameHeaderView: View {
    let model: GameHeaderModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(model.statusLine.title)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(GameTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.9)

            if !model.statusLine.subtitle.isEmpty {
                Text(model.statusLine.subtitle)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
            }

            if !model.metaText.isEmpty {
                Label(model.metaText, systemImage: "ellipsis.message")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, GameTheme.compactPadding)
        .padding(.vertical, 10)
        .background(GameTheme.surface.opacity(0.88))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(GameTheme.outline.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
        .shadow(color: GameTheme.sectionShadow, radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
    }
}

struct GameCommandBarView: View {
    let title: String
    let progressIndex: Int?
    let progressCount: Int
    let onMenuTap: () -> Void

    var body: some View {
        ZStack {
            HStack {
                Button(action: onMenuTap) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(GameTheme.ink)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(GameTheme.surface)
                                .shadow(color: .black.opacity(0.16), radius: 3, x: 0, y: 1)
                        )
                        .overlay(
                            Circle()
                                .stroke(GameTheme.outline.opacity(0.24), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open game tray")

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Image(systemName: "cube.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.08, green: 0.47, blue: 0.78),
                                Color(red: 0.05, green: 0.27, blue: 0.52),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.16), radius: 1.5, x: 0, y: 1)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(GameTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    if let progressIndex {
                        HStack(spacing: 10) {
                            ForEach(0..<max(progressCount, 1), id: \.self) { index in
                                Circle()
                                    .fill(index == progressIndex ? Color(red: 0.08, green: 0.42, blue: 0.72) : GameTheme.outline.opacity(0.25))
                                    .frame(width: 6.5, height: 6.5)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, progressIndex == nil ? 9 : 7)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(GameTheme.surface)
                    .shadow(color: .black.opacity(0.16), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(GameTheme.outline.opacity(0.22), lineWidth: 1)
            )
            .frame(maxWidth: 224)
        }
        .padding(.horizontal, GameTheme.shellPadding)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
