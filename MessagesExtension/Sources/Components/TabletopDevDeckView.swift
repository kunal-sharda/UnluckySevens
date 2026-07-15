import SwiftUI

struct TabletopDevDeckView: View {
    let size: CGSize

    init(size: CGSize = CGSize(width: 48, height: 58)) {
        self.size = size
    }

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: min(size.width, size.height) * 0.14)
                    .fill(Color(red: 0.05, green: 0.33, blue: 0.52))
                    .overlay(
                        RoundedRectangle(cornerRadius: min(size.width, size.height) * 0.14)
                            .stroke(
                                Color(red: 0.62, green: 0.78, blue: 0.82).opacity(0.50),
                                lineWidth: 1
                            )
                    )
                    .offset(x: CGFloat(index) * -1.5, y: CGFloat(index) * 1.5)
            }

            Image(systemName: "sparkle")
                .font(.system(size: size.width * 0.43, weight: .semibold))
                .foregroundStyle(GameTheme.surface)
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
        .accessibilityHidden(true)
    }
}
