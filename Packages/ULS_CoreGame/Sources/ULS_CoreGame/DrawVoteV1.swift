import Foundation

public struct DrawVoteV1: Codable, Equatable {
    public let proposedBy: String
    public let approvals: [String]

    public init(proposedBy: String, approvals: [String]) {
        self.proposedBy = proposedBy
        self.approvals = approvals
    }

    internal func canonicalJSONValue() -> [String: Any] {
        [
            "proposedBy": proposedBy,
            "approvals": approvals,
        ]
    }
}
