import Foundation

protocol SelectionWatchScheduledTask: AnyObject {
    func cancel()
}

@MainActor
protocol SelectionWatchScheduler: AnyObject {
    func schedule(
        after delay: TimeInterval,
        action: @escaping @MainActor () -> Void
    ) -> any SelectionWatchScheduledTask
}

@MainActor
final class MainQueueSelectionWatchScheduler: SelectionWatchScheduler {
    func schedule(
        after delay: TimeInterval,
        action: @escaping @MainActor () -> Void
    ) -> any SelectionWatchScheduledTask {
        let workItem = DispatchWorkItem {
            Task { @MainActor in
                action()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        return DispatchWorkItemSelectionWatchTask(workItem: workItem)
    }
}

private final class DispatchWorkItemSelectionWatchTask: SelectionWatchScheduledTask {
    private let workItem: DispatchWorkItem

    init(workItem: DispatchWorkItem) {
        self.workItem = workItem
    }

    func cancel() {
        workItem.cancel()
    }
}

/// Repeats selected-message hydration while a caller says the current selection remains watchable.
/// It never changes canonical state itself; its callback is the sole refresh path.
@MainActor
final class SelectionWatchLifecycle<Context> {
    private let initialDelay: TimeInterval
    private let pollingInterval: TimeInterval
    private let scheduler: any SelectionWatchScheduler
    private let refresh: (Context) -> Bool

    private var generation = 0
    private var scheduledTask: (any SelectionWatchScheduledTask)?

    init(
        initialDelay: TimeInterval = 0.2,
        pollingInterval: TimeInterval = 1.5,
        scheduler: (any SelectionWatchScheduler)? = nil,
        refresh: @escaping (Context) -> Bool
    ) {
        self.initialDelay = initialDelay
        self.pollingInterval = pollingInterval
        self.scheduler = scheduler ?? MainQueueSelectionWatchScheduler()
        self.refresh = refresh
    }

    func start(watching context: Context) {
        cancel()
        let activeGeneration = generation
        schedule(context: context, generation: activeGeneration, delay: initialDelay)
    }

    func cancel() {
        generation += 1
        scheduledTask?.cancel()
        scheduledTask = nil
    }

    private func schedule(context: Context, generation: Int, delay: TimeInterval) {
        scheduledTask = scheduler.schedule(after: delay) { [weak self] in
            self?.poll(context: context, generation: generation)
        }
    }

    private func poll(context: Context, generation: Int) {
        guard generation == self.generation else {
            return
        }
        scheduledTask = nil

        let shouldContinueWatching = refresh(context)
        guard generation == self.generation else {
            return
        }
        guard shouldContinueWatching else {
            cancel()
            return
        }

        schedule(context: context, generation: generation, delay: pollingInterval)
    }

    deinit {
        scheduledTask?.cancel()
    }
}
