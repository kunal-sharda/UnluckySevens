#if DEBUG
import SwiftUI
import ULS_CoreGame

/// A fixture-only exploration on the same mounted table as the shipping cards.
struct GameTableReferencePreview<Content: View>: View {
    let title: String
    let close: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        ViewThatFits(in: .vertical) {
            page.fixedSize(horizontal: false, vertical: true)
            ScrollView { page }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: 362)
        .foregroundStyle(GameTheme.felt)
        .background(GameTheme.surface, in: RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.6)))
        .buttonStyle(.plain)
    }

    private var page: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(GameTheme.titleFont).accessibilityAddTraits(.isHeader)
                Spacer()
                Button(action: close) {
                    Image(systemName: "xmark").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close " + title)
                .accessibilityIdentifier("uls.purchase.close")
            }
            Divider()
            content
        }
    }
}

struct GameReferenceAwardPreview: View {
    let title: String
    let detail: String
    @Binding var expanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { expanded.toggle() } label: {
                HStack {
                    Text(title).font(.subheadline.bold())
                    Text("2 VP").font(.caption)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.caption)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .accessibilityIdentifier("uls.reference.award." + title)
            .accessibilityValue(expanded ? "Expanded" : "Collapsed")
            if expanded { Text(detail).font(.footnote).fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("uls.reference.award.detail") }
        }
    }
}
#endif
