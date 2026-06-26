import SwiftUI

enum GameTheme {
    static let appBackground = LinearGradient(
        colors: [
            Color(red: 0.15, green: 0.20, blue: 0.17),
            Color(red: 0.22, green: 0.29, blue: 0.24),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let felt = Color(red: 0.18, green: 0.25, blue: 0.20)
    static let feltRaised = Color(red: 0.24, green: 0.31, blue: 0.25)
    static let surface = Color(red: 0.96, green: 0.91, blue: 0.80)
    static let surfaceRaised = Color(red: 0.89, green: 0.80, blue: 0.64)
    static let outline = Color(red: 0.28, green: 0.20, blue: 0.13)
    static let accent = Color(red: 0.92, green: 0.63, blue: 0.18)
    static let ink = Color(red: 0.14, green: 0.10, blue: 0.07)
    static let mutedInk = Color(red: 0.38, green: 0.30, blue: 0.21)
    static let water = Color(red: 0.07, green: 0.42, blue: 0.47)

    static let wood = Color(red: 0.53, green: 0.35, blue: 0.19)
    static let brick = Color(red: 0.69, green: 0.25, blue: 0.20)
    static let sheep = Color(red: 0.35, green: 0.57, blue: 0.26)
    static let wheat = Color(red: 0.87, green: 0.70, blue: 0.17)
    static let ore = Color(red: 0.39, green: 0.44, blue: 0.47)

    static let sectionSpacing: CGFloat = 16
    static let blockSpacing: CGFloat = 12
    static let inlineSpacing: CGFloat = 8
    static let chipSpacing: CGFloat = 6
    static let shellPadding: CGFloat = 16
    static let compactPadding: CGFloat = 12

    static let largeRadius: CGFloat = 22
    static let mediumRadius: CGFloat = 16
    static let smallRadius: CGFloat = 12

    static let sectionShadow = Color.black.opacity(0.10)
    static let trayShadow = Color.black.opacity(0.16)
    static let pressedScale: CGFloat = 0.98
    static let quickAnimation = Animation.easeInOut(duration: 0.18)

    static let titleFont = Font.system(.title3, design: .serif).bold()
    static let headingFont = Font.system(.headline, design: .rounded).bold()
    static let bodyFont = Font.system(.body, design: .rounded)
    static let metaFont = Font.system(.subheadline, design: .rounded)
    static let chipFont = Font.system(.footnote, design: .rounded).bold()
}
