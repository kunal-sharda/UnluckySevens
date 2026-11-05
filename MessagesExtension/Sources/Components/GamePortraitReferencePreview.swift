#if DEBUG
import SwiftUI
import ULS_CoreGame

struct BuildReferenceAnchor: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? { nil }
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

/// The cover and reference share a paper outline throughout pickup and return.
struct GamePortraitReferencePreview: View {
    let origin: CGRect
    let size: CGSize
    let lifted: Bool
    let policy: GameMotionPolicy
    let items: [GameBuildShelfItem]
    let playerColor: Color
    let onBuild: (GameBuildShelfItem.Kind) -> Void
    let onDev: () -> Void
    let onClose: () -> Void
    @State private var expanded = false

    private let paper = Color(red: 0.98, green: 0.95, blue: 0.85)
    private let ink = Color(red: 0.09, green: 0.22, blue: 0.21)
    private var width: CGFloat { min(390, size.width - 28, (size.height - 66) / 1.53) }
    private var height: CGFloat { width * 1.53 }
    private var tuckedScale: CGFloat { min(origin.width / width, origin.height / height) }
    private var center: CGPoint { CGPoint(x: size.width / 2, y: size.height / 2 + 10) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if lifted {
                GameTheme.felt.opacity(0.7).contentShape(Rectangle())
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.title3.weight(.medium))
                        .foregroundStyle(paper).frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .accessibilityLabel("Put away Build Costs")
                .accessibilityIdentifier("uls.purchase.close")
                .position(x: center.x + width / 2 - 16, y: center.y - height / 2 - 21)
                .zIndex(2)
            }
            if policy.animatesSpatialMotion {
                face.scaleEffect(lifted ? 1 : tuckedScale)
                    .position(lifted ? center : CGPoint(x: origin.midX, y: origin.midY))
            } else if lifted {
                face.position(center).transition(.opacity)
            } else {
                face.scaleEffect(tuckedScale).position(x: origin.midX, y: origin.midY).transition(.opacity)
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(lifted)
        .accessibilityHidden(!lifted)
        .animation(policy.resolvedAnimation(.easeInOut(duration: 0.38)), value: lifted)
        .onChange(of: lifted) { _, open in if !open { expanded = false } }
    }

    private var face: some View {
        ZStack {
            if lifted {
                ViewThatFits(in: .vertical) {
                    contents.fixedSize(horizontal: false, vertical: true)
                    ScrollView { contents }
                }
                .padding(24)
            } else {
                VStack(spacing: 16) {
                    roadMark.frame(width: width * 0.74)
                    Text("Build\nCosts")
                        .font(.system(size: width * 0.21, weight: .semibold))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(width: width, height: height)
        .foregroundStyle(ink)
        .background(paper, in: RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 11).inset(by: 8).stroke(ink, lineWidth: 2)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(DragGesture(minimumDistance: 30).onEnded { drag in
            if drag.translation.height > 70 && drag.translation.height > abs(drag.translation.width) { onClose() }
        })
        .accessibilityAction(.escape) { onClose() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.portraitReference.face")
    }

    private var roadMark: some View {
        Image("BuildCostsRoadPrint", bundle: .main)
            .resizable().aspectRatio(contentMode: .fit).accessibilityHidden(true)
    }

    private var contents: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Build Costs").font(.title.bold()).accessibilityAddTraits(.isHeader)
                Spacer()
                roadMark.frame(width: 60)
            }
            Divider()
            ForEach(items) { item in
                Button { onBuild(item.kind) } label: {
                    HStack(spacing: 8) {
                        GameTabletopPiecePropView(kind: piece(item.kind), color: playerColor, isSelected: false)
                            .frame(width: 31, height: 27)
                        Text(item.title).font(.headline)
                        Spacer(minLength: 2)
                        GameBuildCostRow(cost: item.cost)
                    }.frame(minHeight: max(44, height * 0.11)).contentShape(Rectangle())
                }.disabled(!item.isEnabled)
            }
            Button(action: onDev) {
                HStack(spacing: 8) {
                    GameTabletopPortraitCardView(face: .developmentBack, size: CGSize(width: 21, height: 28))
                        .frame(width: 31)
                    Text("Dev Card").font(.headline)
                    Spacer()
                    GameBuildCostRow(cost: CoreBuildCostsV1.developmentCard)
                }.frame(minHeight: max(44, height * 0.11)).contentShape(Rectangle())
            }
            Divider()
            GameReferenceAwardPreview(title: "Longest Road", detail: "Connect at least 5 roads in one continuous route. To take Longest Road from another player, build a longer route.", expanded: $expanded)
        }.buttonStyle(.plain)
    }

    private func piece(_ kind: GameBuildShelfItem.Kind) -> GameTabletopPiecePropView.Kind {
        switch kind {
        case .buildRoad: .road
        case .buildSettlement: .settlement
        case .buildCity: .city
        }
    }
}
#endif
