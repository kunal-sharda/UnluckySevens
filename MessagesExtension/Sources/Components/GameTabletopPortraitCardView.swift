import SwiftUI
import ULS_CoreGame

struct GameTabletopPortraitCardView: View {
    enum Face {
        case resource(ResourceV1)
        case developmentBack
        case ownedDevelopment(GameDevCardVisualKind)
    }

    let face: Face
    let size: CGSize
    let count: Int?
    let overlayText: String?
    let isFaded: Bool
    let stackDepth: Int
    let assetBundle: Bundle

    init(
        face: Face,
        size: CGSize = CGSize(width: 38, height: 47),
        count: Int? = nil,
        overlayText: String? = nil,
        isFaded: Bool = false,
        stackDepth: Int = 1,
        assetBundle: Bundle = .main
    ) {
        self.face = face
        self.size = size
        self.count = count
        self.overlayText = overlayText
        self.isFaded = isFaded
        self.stackDepth = max(stackDepth, 1)
        self.assetBundle = assetBundle
    }

    var body: some View {
        ZStack {
            ForEach((0..<stackDepth).reversed(), id: \.self) { index in
                cardLayer
                    .offset(
                        x: CGFloat(index) * -1.7,
                        y: CGFloat(index) * 1.7
                    )
            }

            if let visibleOverlayText {
                Text(visibleOverlayText)
                    .font(overlayText == nil ? .caption.bold() : .body.weight(.heavy))
                    .monospacedDigit()
                    .foregroundStyle(countInk)
            }
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: .black.opacity(0.24), radius: 1.8, x: 0, y: 1.5)
        .accessibilityHidden(true)
    }

    private var cardLayer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: min(size.width, size.height) * 0.14)
                .fill(cardFill)

            cardMark
                .opacity(visibleOverlayText == nil ? 1 : 0.16)
        }
        .frame(width: size.width, height: size.height)
        .saturation(isFaded ? fadedSaturation : 1)
        .opacity(isFaded ? fadedOpacity : 1)
        .overlay {
            RoundedRectangle(cornerRadius: min(size.width, size.height) * 0.14)
                .stroke(cardStroke, lineWidth: 1)
        }
        .overlay(alignment: .top) {
            Capsule()
                .fill(.white.opacity(0.13))
                .frame(width: size.width * 0.64, height: 1)
                .padding(.top, 1)
        }
    }

    @ViewBuilder
    private var cardMark: some View {
        switch face {
        case let .resource(resource):
            GameTabletopResourceStampView(
                resource: resource,
                size: CGSize(width: size.width * 0.45, height: size.height * 0.42),
                usesMiniatureAsset: false,
                assetBundle: assetBundle
            )
        case .developmentBack:
            Image("factory", bundle: assetBundle)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: size.width * 0.64, height: size.height * 0.56)
        case let .ownedDevelopment(kind):
            Image(systemName: kind.systemImage)
                .font(.system(size: size.width * 0.36, weight: .semibold))
                .foregroundStyle(GamePhysicalTurnPalette.devCardInk)
        }
    }

    private var cardFill: Color {
        switch face {
        case let .resource(resource):
            return resource.tabletopCardFill
        case .developmentBack, .ownedDevelopment:
            return GamePhysicalTurnPalette.devCardFill
        }
    }

    private var cardStroke: Color {
        switch face {
        case .developmentBack, .ownedDevelopment:
            return GamePhysicalTurnPalette.devCardEdge.opacity(0.90)
        case let .resource(resource):
            return resource.tabletopEdge.opacity(0.88)
        }
    }

    private var countInk: Color {
        if overlayText != nil {
            return GamePhysicalTurnPalette.publicPileRevealInk
        }
        switch face {
        case .developmentBack, .ownedDevelopment:
            return GamePhysicalTurnPalette.publicPileRevealInk
        default:
            return GamePhysicalTurnPalette.cardCountInk
        }
    }

    private var fadedSaturation: Double {
        switch face {
        case .developmentBack, .ownedDevelopment:
            return 1
        case .resource:
            return 0.48
        }
    }

    private var fadedOpacity: Double {
        switch face {
        case .developmentBack, .ownedDevelopment:
            return 0.92
        case .resource:
            return 0.72
        }
    }

    private var visibleOverlayText: String? {
        overlayText ?? count.map { String($0) }
    }
}

/// The canonical resource-card treatment used when the player's physical hand
/// is laid out on the felt. Interaction-specific chrome belongs outside it so
/// hand, discard, and future resource choices keep the same card proportions.
struct GamePhysicalResourceHandCardView: View {
    let chip: GameHandChip
    let isFaded: Bool

    var body: some View {
        GameTabletopPortraitCardView(
            face: .resource(chip.resource),
            size: GamePhysicalTurnLayout.handCardSize,
            count: chip.count,
            isFaded: isFaded,
            stackDepth: 1
        )
    }
}
