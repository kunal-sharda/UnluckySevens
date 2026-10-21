import XCTest
@testable import MessagesExtensionSupport

final class ReliabilityPublicationPreparationTests: XCTestCase {
    private final class Failure: Error {}

    func testPreparationFailurePreservesErrorAndStopsAtFailingBoundary() {
        for failingStep in 0...2 {
            let failure = Failure()
            var steps: [Int] = []
            var observations: [String] = []
            func step(_ number: Int) throws -> Int {
                steps.append(number)
                if number == failingStep { throw failure }
                return number
            }
            XCTAssertThrowsError(try ReliabilityPublicationPreparation.run(
                encode: { try step(0) },
                resolveSession: { try step(1) },
                buildMessage: { _, _ in try step(2) },
                record: { action, boundary, outcome, session in
                    observations.append("\(action.rawValue)/\(boundary.rawValue)/\(outcome.rawValue)/\(session.map(String.init) ?? "unknown")")
                }
            )) { error in
                XCTAssertTrue((error as? Failure) === failure)
            }
            XCTAssertEqual(steps, Array(0...failingStep))
            let expected = ["publication/encoding/failed/unknown", "recovery/recovery/unavailable/false",
                            "publication/encoding/failed/true"]
            XCTAssertEqual(observations, [expected[failingStep]])
        }
    }

    func testSuccessfulPreparationReturnsSameValuesWithoutClaimingHandoffOrSelection() throws {
        var observations: [ReliabilityDiagnosticBuffer.Boundary] = []
        let prepared = try ReliabilityPublicationPreparation.run(
            encode: { "encoded" },
            resolveSession: { 42 },
            buildMessage: { encoded, session in "\(encoded):\(session)" },
            record: { action, boundary, outcome, session in
                XCTAssertEqual(action, .publication)
                XCTAssertEqual(outcome, .accepted)
                XCTAssertEqual(session, true)
                observations.append(boundary)
            }
        )
        XCTAssertEqual(prepared.message, "encoded:42")
        XCTAssertEqual(prepared.session, 42)
        XCTAssertEqual(observations, [.encoding])
    }
}
