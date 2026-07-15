import SwiftUI

enum GameTheme {
    static let appBackground = LinearGradient(
        colors: [
            Color(red: 0.11, green: 0.17, blue: 0.13),
            Color(red: 0.18, green: 0.25, blue: 0.20),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let felt = Color(red: 0.13, green: 0.20, blue: 0.16)
    static let feltRaised = Color(red: 0.17, green: 0.25, blue: 0.20)
    static let surface = Color(red: 0.96, green: 0.91, blue: 0.79)
    static let surfaceRaised = Color(red: 0.88, green: 0.79, blue: 0.62)
    static let outline = Color(red: 0.28, green: 0.20, blue: 0.13)
    static let accent = Color(red: 0.92, green: 0.63, blue: 0.18)
    static let commandAccent = Color(red: 0.08, green: 0.42, blue: 0.72)
    static let ink = Color(red: 0.14, green: 0.10, blue: 0.07)
    static let mutedInk = Color(red: 0.38, green: 0.30, blue: 0.21)
    static let water = Color(red: 0.07, green: 0.42, blue: 0.47)
    static let boardFrame = Color(red: 0.91, green: 0.84, blue: 0.68)

    static let wood = Color(red: 0.25, green: 0.47, blue: 0.18)
    static let brick = Color(red: 0.74, green: 0.30, blue: 0.16)
    static let sheep = Color(red: 0.55, green: 0.68, blue: 0.31)
    static let wheat = Color(red: 0.86, green: 0.66, blue: 0.18)
    static let ore = Color(red: 0.40, green: 0.45, blue: 0.45)

    static let sectionSpacing: CGFloat = 10
    static let blockSpacing: CGFloat = 12
    static let inlineSpacing: CGFloat = 8
    static let chipSpacing: CGFloat = 6
    static let shellPadding: CGFloat = 12
    static let compactPadding: CGFloat = 12

    static let largeRadius: CGFloat = 24
    static let mediumRadius: CGFloat = 16
    static let smallRadius: CGFloat = 10

    static let sectionShadow = Color.black.opacity(0.12)
    static let trayShadow = Color.black.opacity(0.18)
    static let pressedScale: CGFloat = 0.98
    static let quickAnimation = Animation.easeInOut(duration: 0.18)

    static let titleFont = Font.system(.title3, design: .serif).bold()
    static let headingFont = Font.system(.headline, design: .rounded).bold()
    static let bodyFont = Font.system(.body, design: .rounded)
    static let metaFont = Font.system(.subheadline, design: .rounded)
    static let chipFont = Font.system(.footnote, design: .rounded).bold()
}
