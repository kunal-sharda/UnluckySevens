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

    var label: String {
        switch self {
        case .url:
            return "URL"
        case .summaryFallback:
            return "summary fallback"
        case .local:
            return "local"
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

        if includeSummaryPayloadMirror {
            message.summaryText = "\(summaryPayloadPrefix)\(encodedEnvelope)"
        } else {
            message.summaryText = summaryLabel
        }

        return TranscriptBuiltMessage(
            message: message,
            urlString: url.absoluteString,
            payloadLength: encodedEnvelope.count,
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

        guard
            let summaryText,
            summaryText.hasPrefix(summaryPayloadPrefix)
        else {
            return nil
        }

        let start = summaryText.index(summaryText.startIndex, offsetBy: summaryPayloadPrefix.count)
        let payload = String(summaryText[start...])
        guard !payload.isEmpty else {
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
}
