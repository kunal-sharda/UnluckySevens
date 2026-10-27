import SwiftUI
import ULS_CoreGame

struct GameBuildCostRow: View {
    let cost: ResourceHandV1
    var body: some View {
        HStack(spacing: 7) {
            ForEach(ResourceV1.allCases.filter { cost.count(for: $0) > 0 }, id: \.self) { resource in
                HStack(spacing: 3) {
                    GameTabletopPortraitCardView(face: .resource(resource), size: CGSize(width: 17, height: 23))
                    if cost.count(for: resource) > 1 { Text("×\(cost.count(for: resource))").font(.caption.bold()) }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(cost.count(for: resource)) \(resource.shortLabel)")
            }
        }
    }
}
