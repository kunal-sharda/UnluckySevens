import SwiftUI

struct GamePhysicalDicePairView: View {
    let isRolling: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isRolling)) { timeline in
            let tick = Int(timeline.date.timeIntervalSinceReferenceDate * 15)
            let phase = timeline.date.timeIntervalSinceReferenceDate * 19

            HStack(spacing: 10) {
                GamePhysicalDieView(
                    value: isRolling ? ((tick % 6) + 1) : 3,
                    size: 42
                )
                .rotationEffect(.degrees(isRolling ? phase * 28 : -7))
                .rotation3DEffect(
                    .degrees(isRolling ? phase * 17 : 0),
                    axis: (x: 0.7, y: 0.4, z: 0.2)
                )
                .offset(
                    x: isRolling ? sin(phase) * 8 : 0,
                    y: isRolling ? -abs(cos(phase * 0.74)) * 13 : 2
                )

                GamePhysicalDieView(
                    value: isRolling ? (((tick + 3) % 6) + 1) : 5,
                    size: 42
                )
                .rotationEffect(.degrees(isRolling ? -phase * 31 : 8))
                .rotation3DEffect(
                    .degrees(isRolling ? -phase * 21 : 0),
                    axis: (x: 0.35, y: 0.8, z: 0.25)
                )
                .offset(
                    x: isRolling ? cos(phase * 0.91) * 8 : 0,
                    y: isRolling ? -abs(sin(phase * 0.68)) * 15 : -1
                )
            }
        }
        .frame(width: 108, height: 66)
        .accessibilityHidden(true)
    }
}
