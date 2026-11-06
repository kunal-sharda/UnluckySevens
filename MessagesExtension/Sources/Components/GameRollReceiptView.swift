import SwiftUI
import ULS_CoreGame

struct GameRollReceiptView: View {
    let receipt: ProductionReceiptV1
    let rollerName: String

    static func announcement(receipt: ProductionReceiptV1, rollerName: String) -> String {
        var parts = ["\(rollerName) rolled \(receipt.roll.d1) plus \(receipt.roll.d2), total \(receipt.roll.d1 + receipt.roll.d2)."]
        if receipt.roll.d1 + receipt.roll.d2 == 7 {
            parts.append("No production. Follow the discard and robber prompts.")
        } else {
            let resources: [ResourceV1] = [.wood, .brick, .sheep, .wheat, .ore]
            let gains = resources.filter { receipt.gains.count(for: $0) > 0 }
                .map { "\(receipt.gains.count(for: $0)) \($0.rawValue)" }.joined(separator: ", ")
            parts.append(gains.isEmpty ? "You received no resources." : "You received \(gains).")
            if receipt.blockedByRobber { parts.append("The robber blocked some of your production.") }
            if receipt.bankShortage { parts.append("The Bank could not supply some of your production.") }
        }
        return parts.joined(separator: " ")
    }

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
        .accessibilityLabel(Self.announcement(receipt: receipt, rollerName: rollerName))
        .accessibilityIdentifier("uls.roll.privateReceipt")
    }
}
