import Foundation

public enum TransportError: Error, Equatable {
    case emptyPayload
    case invalidBase64URL
    case invalidJSON
    case unsupportedVersion(Int)
}

extension TransportError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyPayload:
            return "Envelope payload is empty."
        case .invalidBase64URL:
            return "Envelope payload is not valid base64url."
        case .invalidJSON:
            return "Envelope payload JSON is invalid."
        case let .unsupportedVersion(version):
            return "Unsupported envelope version: \(version)."
        }
    }
}
