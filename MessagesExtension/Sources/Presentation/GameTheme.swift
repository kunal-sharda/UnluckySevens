import SwiftUI

enum GameTheme {
    static let appBackground = LinearGradient(
        colors: [
            Color(red: 0.97, green: 0.93, blue: 0.86),
            Color(red: 0.90, green: 0.82, blue: 0.70),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let surface = Color(red: 0.96, green: 0.92, blue: 0.85)
    static let surfaceRaised = Color(red: 0.89, green: 0.80, blue: 0.66)
    static let outline = Color(red: 0.39, green: 0.24, blue: 0.14)
    static let accent = Color(red: 0.77, green: 0.40, blue: 0.18)
    static let ink = Color(red: 0.20, green: 0.13, blue: 0.08)
    static let mutedInk = Color(red: 0.39, green: 0.28, blue: 0.20)

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
    static let pressedScale: CGFloat = 0.98
    static let quickAnimation = Animation.easeInOut(duration: 0.18)

    static let titleFont = Font.system(.title3, design: .serif).bold()
    static let headingFont = Font.system(.headline, design: .rounded).bold()
    static let bodyFont = Font.system(.body, design: .rounded)
    static let metaFont = Font.system(.subheadline, design: .rounded)
    static let chipFont = Font.system(.footnote, design: .rounded).bold()
}
