import XCTest
@testable import MessagesExtensionSupport

@MainActor
final class MessagesHostLayoutStoreTests: XCTestCase {
    func testInitialMeasurementPublishesActualUsableCanvas() throws {
        let store = MessagesHostLayoutStore()

        store.observe(
            measurement(
                size: CGSize(width: 820, height: 1180),
                insets: MessagesHostInsets(
                    top: 24,
                    leading: 0,
                    bottom: 20,
                    trailing: 0
                ),
                style: .expanded
            )
        )

        let snapshot = try XCTUnwrap(store.snapshot)
        XCTAssertEqual(snapshot.boundsSize, CGSize(width: 820, height: 1180))
        XCTAssertEqual(snapshot.usableSize, CGSize(width: 820, height: 1136))
        XCTAssertEqual(snapshot.presentationStyle, .expanded)
        XCTAssertEqual(snapshot.revision, 1)
    }

    func testEquivalentMeasurementsDoNotRepublish() throws {
        let store = MessagesHostLayoutStore()
        store.observe(measurement(size: CGSize(width: 402, height: 707)))
        let initial = try XCTUnwrap(store.snapshot)

        store.observe(measurement(size: CGSize(width: 402.8, height: 706.4)))

        XCTAssertEqual(store.snapshot, initial)
    }

    func testTransitionPublishesOnlyFinalMeasurement() throws {
        let store = MessagesHostLayoutStore()
        store.observe(measurement(size: CGSize(width: 402, height: 707), style: .expanded))
        store.beginTransition()
        store.observe(measurement(size: CGSize(width: 402, height: 620), style: .expanded))
        store.observe(measurement(size: CGSize(width: 402, height: 540), style: .compact))

        XCTAssertEqual(try XCTUnwrap(store.snapshot).revision, 1)

        store.completeTransition(
            with: measurement(size: CGSize(width: 402, height: 420), style: .compact)
        )

        let settled = try XCTUnwrap(store.snapshot)
        XCTAssertEqual(settled.boundsSize, CGSize(width: 402, height: 420))
        XCTAssertEqual(settled.presentationStyle, .compact)
        XCTAssertEqual(settled.revision, 2)
    }

    func testSizeOnlyChangeDebouncesToOneSettledRevision() async throws {
        let store = MessagesHostLayoutStore()
        store.observe(measurement(size: CGSize(width: 402, height: 707)))

        store.observe(
            measurement(size: CGSize(width: 390, height: 700)),
            settleDelayNanoseconds: 2_000_000
        )
        store.observe(
            measurement(size: CGSize(width: 380, height: 690)),
            settleDelayNanoseconds: 2_000_000
        )
        try await Task.sleep(nanoseconds: 10_000_000)

        let settled = try XCTUnwrap(store.snapshot)
        XCTAssertEqual(settled.boundsSize, CGSize(width: 380, height: 690))
        XCTAssertEqual(settled.revision, 2)
    }

    func testBottomClearanceCountsExistingSafeAreaFirst() {
        let zeroInset = snapshot(bottomInset: 0)
        let partialInset = snapshot(bottomInset: 5)
        let phoneInset = snapshot(bottomInset: 34)

        XCTAssertEqual(zeroInset.additionalBottomClearance, 13)
        XCTAssertEqual(partialInset.additionalBottomClearance, 8)
        XCTAssertEqual(phoneInset.additionalBottomClearance, 0)
    }

    func testRepresentativeHostFixturesResolveWithoutDeviceIdentity() {
        let fixtures: [(CGSize, MessagesHostLayoutProfile)] = [
            (CGSize(width: 402, height: 707), .narrowShort),
            (CGSize(width: 430, height: 874), .narrow),
            (CGSize(width: 520, height: 620), .narrowShort),
            (CGSize(width: 640, height: 760), .standard),
            (CGSize(width: 820, height: 620), .wideShort),
            (CGSize(width: 820, height: 1136), .wide),
        ]

        for (size, expectedProfile) in fixtures {
            let store = MessagesHostLayoutStore()
            store.observe(measurement(size: size))
            XCTAssertEqual(store.snapshot?.profile, expectedProfile, "Unexpected profile for \(size)")
        }
    }

    func testTransitionCompletionSuppressesEquivalentFinalMeasurement() throws {
        let store = MessagesHostLayoutStore()
        let initial = measurement(size: CGSize(width: 402, height: 707))
        store.observe(initial)
        store.beginTransition()
        store.completeTransition(with: initial)

        XCTAssertEqual(try XCTUnwrap(store.snapshot).revision, 1)
    }

    func testInvalidNegativeSafeAreaMeasurementIsIgnoredUntilValidGeometryArrives() throws {
        let store = MessagesHostLayoutStore()

        store.observe(
            measurement(
                size: CGSize(width: 402, height: 802),
                insets: MessagesHostInsets(top: -130, leading: 0, bottom: 184, trailing: 0)
            )
        )
        XCTAssertNil(store.snapshot)

        store.observe(
            measurement(
                size: CGSize(width: 402, height: 802),
                insets: MessagesHostInsets(top: 20, leading: 0, bottom: 34, trailing: 0)
            )
        )
        let settled = try XCTUnwrap(store.snapshot)
        XCTAssertEqual(settled.safeAreaInsets.top, 20)
        XCTAssertEqual(settled.usableSize.height, 748)
        XCTAssertEqual(settled.revision, 1)
    }

    func testInvalidTransitionCompletionKeepsLastSnapshotAndAllowsNextObservation() async throws {
        let store = MessagesHostLayoutStore()
        store.observe(measurement(size: CGSize(width: 402, height: 748)))
        let initial = try XCTUnwrap(store.snapshot)

        store.beginTransition()
        store.completeTransition(
            with: measurement(
                size: CGSize(width: 402, height: 802),
                insets: MessagesHostInsets(top: -130, leading: 0, bottom: 184, trailing: 0)
            )
        )
        XCTAssertEqual(store.snapshot, initial)

        store.observe(
            measurement(size: CGSize(width: 402, height: 802)),
            settleDelayNanoseconds: 2_000_000
        )
        try await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertEqual(store.snapshot?.boundsSize, CGSize(width: 402, height: 802))
        XCTAssertEqual(store.snapshot?.revision, 2)
    }

    private func measurement(
        size: CGSize,
        insets: MessagesHostInsets = .zero,
        style: MessagesHostPresentationStyle = .expanded
    ) -> MessagesHostLayoutStore.Measurement {
        MessagesHostLayoutStore.Measurement(
            boundsSize: size,
            safeAreaInsets: insets,
            presentationStyle: style
        )
    }

    private func snapshot(bottomInset: CGFloat) -> MessagesHostLayoutSnapshot {
        MessagesHostLayoutSnapshot(
            boundsSize: CGSize(width: 402, height: 707),
            safeAreaInsets: MessagesHostInsets(
                top: 0,
                leading: 0,
                bottom: bottomInset,
                trailing: 0
            ),
            presentationStyle: .expanded,
            profile: .narrowShort,
            revision: 1
        )
    }
}
