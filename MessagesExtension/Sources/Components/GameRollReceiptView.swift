import SwiftUI
import ULS_CoreGame

struct GameRollReceiptView: View {
    let receipt: ProductionReceiptV1
    let rollerName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(rollerName) rolled \(receipt.roll.d1) + \(receipt.roll.d2) = \(receipt.roll.d1 + receipt.roll.d2)")
                .font(.headline)
            if receipt.roll.d1 + receipt.roll.d2 == 7 {
                Text("No production. Follow the discard and robber prompts.")
            } else {
                Text(receipt.gains.totalCount == 0 ? "You received no resources." : "You received")
                if receipt.gains.totalCount > 0 { GameBuildCostRow(cost: receipt.gains) }
                if receipt.blockedByRobber { Text("The robber blocked some of your production.") }
                if receipt.bankShortage { Text("The Bank could not supply some of your production.") }
            }
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("uls.roll.privateReceipt")
    }
}
