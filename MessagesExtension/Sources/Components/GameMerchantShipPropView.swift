import SwiftUI

struct GameMerchantShipPropView: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Image("merchant_ship_colored")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(GamePhysicalTurnPalette.selectedKeyline)
                .scaleEffect(1.06)
                .opacity(isSelected ? 1 : 0)

            Image("merchant_ship_colored")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
        }
        .shadow(color: .black.opacity(isSelected ? 0.30 : 0.20), radius: 1.5, x: 0, y: 1)
        .accessibilityHidden(true)
    }
}
