import SwiftUI

struct GameMotionPolicy: Equatable {
    let skipsAnimations: Bool
    let reducesMotion: Bool

    var animatesSpatialMotion: Bool {
        !skipsAnimations && !reducesMotion
    }

    var skipsAppAuthoredMotion: Bool {
        skipsAnimations
    }

    func resolvedAnimation(_ animation: Animation = .easeInOut(duration: 0.18)) -> Animation? {
        if skipsAnimations {
            return nil
        }
        if reducesMotion {
            return .easeOut(duration: 0.08)
        }
        return animation
    }
}
