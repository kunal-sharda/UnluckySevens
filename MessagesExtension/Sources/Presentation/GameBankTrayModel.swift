import ULS_CoreGame

struct GameBankChip: Identifiable, Equatable {
    let resource: ResourceV1
    let count: Int
    let detailText: String?
    let isEnabled: Bool
    let isSelected: Bool
    let selectionIndex: Int?

    var id: String { resource.rawValue }
}

struct GameBankTrayModel: Equatable {
    let title: String
    let subtitle: String?
    let chips: [GameBankChip]
}
