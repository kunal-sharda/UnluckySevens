import Combine
import CoreGraphics
import Foundation

@MainActor
final class MessagesHostLayoutStore: ObservableObject {
    struct Measurement: Equatable {
        let boundsSize: CGSize
        let safeAreaInsets: MessagesHostInsets
        let presentationStyle: MessagesHostPresentationStyle
    }

    @Published private(set) var snapshot: MessagesHostLayoutSnapshot?

    private var pendingMeasurement: Measurement?
    private var isTransitioning = false
    private var settleTask: Task<Void, Never>?

    func beginTransition() {
        isTransitioning = true
        settleTask?.cancel()
        settleTask = nil
    }

    func observe(
        _ measurement: Measurement,
        settleDelayNanoseconds: UInt64 = 180_000_000
    ) {
        guard measurement.boundsSize.width > 0, measurement.boundsSize.height > 0 else {
            return
        }
        pendingMeasurement = measurement

        if snapshot == nil {
            commitPendingMeasurement()
            return
        }
        guard !isTransitioning, !isEquivalentToSnapshot(measurement) else {
            return
        }

        settleTask?.cancel()
        settleTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: settleDelayNanoseconds)
            guard !Task.isCancelled else { return }
            self?.commitPendingMeasurement()
        }
    }

    func completeTransition(with measurement: Measurement) {
        guard measurement.boundsSize.width > 0, measurement.boundsSize.height > 0 else {
            return
        }
        pendingMeasurement = measurement
        isTransitioning = false
        settleTask?.cancel()
        settleTask = nil
        commitPendingMeasurement()
    }

    func commitPendingMeasurement() {
        guard let pendingMeasurement else { return }
        self.pendingMeasurement = nil
        guard !isEquivalentToSnapshot(pendingMeasurement) else { return }

        let usableSize = CGSize(
            width: max(
                pendingMeasurement.boundsSize.width
                    - pendingMeasurement.safeAreaInsets.leading
                    - pendingMeasurement.safeAreaInsets.trailing,
                0
            ),
            height: max(
                pendingMeasurement.boundsSize.height
                    - pendingMeasurement.safeAreaInsets.top
                    - pendingMeasurement.safeAreaInsets.bottom,
                0
            )
        )
        snapshot = MessagesHostLayoutSnapshot(
            boundsSize: pendingMeasurement.boundsSize,
            safeAreaInsets: pendingMeasurement.safeAreaInsets,
            presentationStyle: pendingMeasurement.presentationStyle,
            profile: MessagesHostLayoutProfile.resolve(availableSize: usableSize),
            revision: (snapshot?.revision ?? 0) + 1
        )
    }

    private func isEquivalentToSnapshot(_ measurement: Measurement) -> Bool {
        snapshot?.isEquivalentMeasurement(
            boundsSize: measurement.boundsSize,
            safeAreaInsets: measurement.safeAreaInsets,
            presentationStyle: measurement.presentationStyle
        ) == true
    }

    deinit {
        settleTask?.cancel()
    }
}
