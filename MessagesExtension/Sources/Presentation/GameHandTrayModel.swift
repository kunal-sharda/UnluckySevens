struct GameHandTrayModel: Equatable {
    let title: String
    let chips: [GameHandChip]

    var totalCount: Int {
        chips.reduce(0) { $0 + $1.count }
    }
}
