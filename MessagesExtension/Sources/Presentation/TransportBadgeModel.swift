import SwiftUI

struct TransportBadgeModel: Equatable {
    enum Tone: Equatable {
        case url
        case missing

        var label: String {
            switch self {
            case .url:
                return "URL"
            case .missing:
                return "MISSING"
            }
        }

        var fillColor: Color {
            switch self {
            case .url:
                return GameTheme.accent.opacity(0.92)
            case .missing:
                return Color.red.opacity(0.88)
            }
        }
    }

    let text: String
    let tone: Tone

    static let initial = TransportBadgeModel(text: Tone.missing.label, tone: .missing)

    static func build(
        triggerLabel: String,
        snapshot: TranscriptSelectionSnapshot
    ) -> TransportBadgeModel {
        let tone: Tone
        switch snapshot.decodeSource {
        case TranscriptPayloadSource.url.label:
            tone = .url
        default:
            tone = .missing
        }

        let text: String
        if triggerLabel == "-" {
            text = tone.label
        } else {
            text = "\(tone.label) · \(triggerLabel)"
        }

        return TransportBadgeModel(text: text, tone: tone)
    }
}
