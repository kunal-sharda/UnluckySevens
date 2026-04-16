import Foundation
import Messages
import ULS_Transport

enum TranscriptSessionPolicy: Equatable {
    case new
    case state(gameId: String)

    var label: String {
        switch self {
        case .new:
            return "new"
        case let .state(gameId):
            return "state(\(gameId))"
        }
    }
}

enum TranscriptPayloadSource: Equatable {
    case url
    case summaryFallback
    case local
    case localCache

    var label: String {
        switch self {
        case .url:
            return "URL"
        case .summaryFallback:
            return "summary fallback"
        case .local:
            return "local"
        case .localCache:
            return "local cache"
        }
    }
}

enum TranscriptSelectionTrigger: String {
    case viewDidLoad
    case didSelect
    case didReceive
    case selectionPoll
    case reload

    var label: String {
        rawValue
    }
}

struct TranscriptDecodedPayload: Equatable {
    let payload: String
    let source: TranscriptPayloadSource
}

struct TranscriptBuiltMessage {
    let message: MSMessage
    let urlString: String
    let payloadLength: Int
    let mirroredPayloadLength: Int
    let summaryText: String
    let layoutCaption: String
    let sessionPolicy: TranscriptSessionPolicy
}

struct TranscriptSelectionSnapshot: Equatable {
    let messagePresence: String
    let urlPresence: String
    let urlString: String
    let payloadQueryPresence: String
    let payloadLength: String
    let summaryText: String
    let layoutCaption: String
    let sessionPresence: String
    let decodeSource: String
}

enum TranscriptTransportError: LocalizedError {
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not build iMessage payload URL."
        }
    }
}

enum TranscriptTransportSupport {
    static func resolveSessionPolicy(
        requestedPolicy: TranscriptSessionPolicy,
        envelopeKind: EnvelopeV1.Kind,
        useSingleSessionDebug: Bool,
        currentGameId: String?
    ) -> TranscriptSessionPolicy {
        guard
            useSingleSessionDebug,
            envelopeKind == .intent,
            case .new = requestedPolicy,
            let currentGameId
        else {
            return requestedPolicy
        }

        return .state(gameId: currentGameId)
    }

    static func buildMessage(
        encodedEnvelope: String,
        caption: String,
        summaryLabel: String,
        session: MSSession,
        sessionPolicy: TranscriptSessionPolicy,
        summaryPayloadPrefix: String,
        includeSummaryPayloadMirror: Bool
    ) throws -> TranscriptBuiltMessage {
        var components = URLComponents()
        components.scheme = "unluckysevens"
        components.host = "msg"
        components.queryItems = [URLQueryItem(name: "payload", value: encodedEnvelope)]

        guard let url = components.url else {
            throw TranscriptTransportError.invalidURL
        }

        let message = MSMessage(session: session)
        message.url = url

        let layout = MSMessageTemplateLayout()
        layout.caption = caption
        message.layout = layout

        message.summaryText = buildSummaryText(
            summaryLabel: summaryLabel,
            encodedEnvelope: encodedEnvelope,
            summaryPayloadPrefix: summaryPayloadPrefix,
            includeSummaryPayloadMirror: includeSummaryPayloadMirror
        )

        let mirroredPayloadLength: Int
        if
            let mirroredPayload = mirroredPayloadValue(
                from: message.summaryText,
                summaryPayloadPrefix: summaryPayloadPrefix
            )
        {
            mirroredPayloadLength = mirroredPayload.count
        } else {
            mirroredPayloadLength = 0
        }

        return TranscriptBuiltMessage(
            message: message,
            urlString: url.absoluteString,
            payloadLength: encodedEnvelope.count,
            mirroredPayloadLength: mirroredPayloadLength,
            summaryText: message.summaryText ?? "-",
            layoutCaption: caption,
            sessionPolicy: sessionPolicy
        )
    }

    static func decodePayload(
        from url: URL?,
        summaryText: String?,
        summaryPayloadPrefix: String,
        allowSummaryFallback: Bool
    ) -> TranscriptDecodedPayload? {
        if let urlPayload = payloadQueryValue(from: url), !urlPayload.isEmpty {
            return TranscriptDecodedPayload(payload: urlPayload, source: .url)
        }

        guard allowSummaryFallback else {
            return nil
        }

        guard let payload = mirroredPayloadValue(
            from: summaryText,
            summaryPayloadPrefix: summaryPayloadPrefix
        ) else {
            return nil
        }

        return TranscriptDecodedPayload(payload: payload, source: .summaryFallback)
    }

    static func selectionSnapshot(
        for message: MSMessage?,
        summaryPayloadPrefix: String,
        allowSummaryFallback: Bool
    ) -> TranscriptSelectionSnapshot {
        guard let message else {
            return TranscriptSelectionSnapshot(
                messagePresence: "missing",
                urlPresence: "missing",
                urlString: "-",
                payloadQueryPresence: "missing",
                payloadLength: "-",
                summaryText: "-",
                layoutCaption: "-",
                sessionPresence: "missing",
                decodeSource: "-"
            )
        }

        let urlString = message.url?.absoluteString ?? "-"
        let payloadQuery = payloadQueryValue(from: message.url)
        let decodedPayload = decodePayload(
            from: message.url,
            summaryText: message.summaryText,
            summaryPayloadPrefix: summaryPayloadPrefix,
            allowSummaryFallback: allowSummaryFallback
        )
        let layoutCaption = (message.layout as? MSMessageTemplateLayout)?.caption ?? "-"
        let sessionStatus = String(describing: message.session) == "nil" ? "missing" : "present"

        return TranscriptSelectionSnapshot(
            messagePresence: "present",
            urlPresence: message.url == nil ? "missing" : "present",
            urlString: urlString,
            payloadQueryPresence: payloadQuery == nil ? "missing" : "present",
            payloadLength: decodedPayload.map { String($0.payload.count) } ?? "-",
            summaryText: message.summaryText ?? "-",
            layoutCaption: layoutCaption,
            sessionPresence: sessionStatus,
            decodeSource: decodedPayload?.source.label ?? "-"
        )
    }

    private static func payloadQueryValue(from url: URL?) -> String? {
        guard
            let url,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return nil
        }

        return components.queryItems?
            .first(where: { $0.name == "payload" })?
            .value
    }

    private static func mirroredPayloadValue(
        from summaryText: String?,
        summaryPayloadPrefix: String
    ) -> String? {
        guard
            let summaryText,
            let prefixRange = summaryText.range(of: summaryPayloadPrefix)
        else {
            return nil
        }

        let payloadStart = prefixRange.upperBound
        let payloadCandidate = normalizedMirroredPayloadCandidate(
            from: summaryText[payloadStart...]
        )
        guard !payloadCandidate.isEmpty else {
            return nil
        }

        return recoverDecodableEnvelopePrefix(from: payloadCandidate)
    }

    private static func buildSummaryText(
        summaryLabel: String,
        encodedEnvelope: String,
        summaryPayloadPrefix: String,
        includeSummaryPayloadMirror: Bool
    ) -> String {
        guard includeSummaryPayloadMirror else {
            return summaryLabel
        }

        guard !summaryLabel.isEmpty else {
            return "\(summaryPayloadPrefix)\(encodedEnvelope)"
        }

        // Keep the fallback on one line so transcript fallback paths do not
        // expand into a multi-line payload block during phase 12. Put the
        // mirrored payload first so truncation is more likely to preserve it.
        return "\(summaryPayloadPrefix)\(encodedEnvelope) \(summaryLabel)"
    }

    private static func normalizedMirroredPayloadCandidate(
        from suffix: Substring
    ) -> String {
        let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        var scalars: [UnicodeScalar] = []
        var encounteredPayloadCharacter = false

        for scalar in suffix.unicodeScalars {
            if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                continue
            }

            if allowedCharacters.contains(scalar) {
                scalars.append(scalar)
                encounteredPayloadCharacter = true
                continue
            }

            if encounteredPayloadCharacter {
                break
            }
        }

        return String(String.UnicodeScalarView(scalars))
    }

    private static func recoverDecodableEnvelopePrefix(
        from candidate: String
    ) -> String? {
        guard !candidate.isEmpty else {
            return nil
        }

        if isDecodableEnvelope(candidate) {
            return candidate
        }

        var endIndex = candidate.endIndex
        while endIndex > candidate.startIndex {
            endIndex = candidate.index(before: endIndex)
            let prefix = String(candidate[..<endIndex])
            if isDecodableEnvelope(prefix) {
                return prefix
            }
        }

        return nil
    }

    private static func isDecodableEnvelope(_ candidate: String) -> Bool {
        (try? decode(candidate)) != nil
    }
}
