import SwiftUI

enum LobbyPalette {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.10, green: 0.23, blue: 0.20),
            Color(red: 0.06, green: 0.15, blue: 0.14),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let feltHighlight = Color(red: 0.27, green: 0.48, blue: 0.39)
    static let cream = Color(red: 0.97, green: 0.91, blue: 0.78)
    static let mutedCream = Color(red: 0.77, green: 0.74, blue: 0.64)
    static let ink = Color(red: 0.12, green: 0.09, blue: 0.06)
    static let clay = Color(red: 0.72, green: 0.31, blue: 0.15)
    static let moss = Color(red: 0.39, green: 0.55, blue: 0.29)
    static let harbor = Color(red: 0.25, green: 0.43, blue: 0.46)
    static let wood = Color(red: 0.47, green: 0.30, blue: 0.17)
    static let woodEdge = Color(red: 0.24, green: 0.14, blue: 0.08)
    static let openSeat = Color.white.opacity(0.08)
    static let openSeatEdge = cream.opacity(0.34)
}
