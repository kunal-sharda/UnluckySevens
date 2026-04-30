import Foundation

public struct EnvelopeV1: Codable, Equatable {
    public enum Kind: String, Codable, Equatable {
        case state = "STATE"
    }

    public enum Body: Codable, Equatable {
        private enum CodingKeys: String, CodingKey {
            case state
        }

        private struct PayloadContainer: Codable, Equatable {
            let payload: String
        }

        case state(payload: String)

        var kind: Kind {
            .state
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            if let statePayload = try container.decodeIfPresent(PayloadContainer.self, forKey: .state) {
                self = .state(payload: statePayload.payload)
                return
            }

            throw DecodingError.dataCorruptedError(
                forKey: .state,
                in: container,
                debugDescription: "Envelope body must contain a state payload."
            )
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case let .state(payload):
                try container.encode(PayloadContainer(payload: payload), forKey: .state)
            }
        }
    }

    public let v: Int
    public let kind: Kind
    public let body: Body

    public init(v: Int = 1, kind: Kind, body: Body) {
        self.v = v
        self.kind = kind
        self.body = body
    }
}
