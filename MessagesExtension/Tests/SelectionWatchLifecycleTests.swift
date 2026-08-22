import XCTest
@testable import MessagesExtensionSupport

@MainActor
final class SelectionWatchLifecycleTests: XCTestCase {
    func testStartPollsAfterInitialDelayAndRepeatsAtPollingInterval() {
        let scheduler = ControlledSelectionWatchScheduler()
        var refreshedContexts: [String] = []
        let watch = SelectionWatchLifecycle<String>(
            initialDelay: 0.2,
            pollingInterval: 1.5,
            scheduler: scheduler
        ) { context in
            refreshedContexts.append(context)
            return true
        }

        watch.start(watching: "selected-game")
        XCTAssertEqual(scheduler.scheduledDelays, [0.2])

        scheduler.runNext()
        XCTAssertEqual(refreshedContexts, ["selected-game"])
        XCTAssertEqual(scheduler.scheduledDelays, [1.5])

        scheduler.runNext()
        XCTAssertEqual(refreshedContexts, ["selected-game", "selected-game"])
    }

    func testCancellationSuppressesPendingAndAlreadyDeliveredCallbacks() {
        let scheduler = ControlledSelectionWatchScheduler()
        var refreshCount = 0
        let watch = SelectionWatchLifecycle<String>(scheduler: scheduler) { _ in
            refreshCount += 1
            return true
        }

        watch.start(watching: "selected-game")
        watch.cancel()
        scheduler.runNext(ignoringCancellation: true)

        XCTAssertEqual(refreshCount, 0)
        XCTAssertTrue(scheduler.firstTaskWasCancelled)
    }

    func testReplacingSelectionPreventsOldSelectionFromRefreshing() {
        let scheduler = ControlledSelectionWatchScheduler()
        var refreshedContexts: [String] = []
        let watch = SelectionWatchLifecycle<String>(scheduler: scheduler) { context in
            refreshedContexts.append(context)
            return true
        }

        watch.start(watching: "first-game")
        watch.start(watching: "second-game")
        scheduler.runNext(ignoringCancellation: true)
        scheduler.runNext()

        XCTAssertEqual(refreshedContexts, ["second-game"])
    }

    func testRefreshThatStopsWatchingDoesNotScheduleAnotherPoll() {
        let scheduler = ControlledSelectionWatchScheduler()
        let watch = SelectionWatchLifecycle<String>(scheduler: scheduler) { _ in false }

        watch.start(watching: "selected-game")
        scheduler.runNext()

        XCTAssertTrue(scheduler.scheduledDelays.isEmpty)
    }
}

@MainActor
private final class ControlledSelectionWatchScheduler: SelectionWatchScheduler {
    private final class ScheduledTask: SelectionWatchScheduledTask {
        var isCancelled = false

        func cancel() {
            isCancelled = true
        }
    }

    private struct ScheduledAction {
        let delay: TimeInterval
        let task: ScheduledTask
        let action: @MainActor () -> Void
    }

    private var scheduledActions: [ScheduledAction] = []
    private(set) var firstTaskWasCancelled = false

    var scheduledDelays: [TimeInterval] {
        scheduledActions.map(\.delay)
    }

    func schedule(
        after delay: TimeInterval,
        action: @escaping @MainActor () -> Void
    ) -> any SelectionWatchScheduledTask {
        let task = ScheduledTask()
        scheduledActions.append(ScheduledAction(delay: delay, task: task, action: action))
        return task
    }

    func runNext(ignoringCancellation: Bool = false) {
        let next = scheduledActions.removeFirst()
        firstTaskWasCancelled = firstTaskWasCancelled || next.task.isCancelled
        guard ignoringCancellation || !next.task.isCancelled else {
            return
        }
        next.action()
    }
}
