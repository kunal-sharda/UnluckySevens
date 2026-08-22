import Messages
import SwiftUI
import UIKit

@_spi(MessagesHost)
@MainActor
public final class MessagesExtensionHostRuntime {
    public enum PresentationStyle {
        case compact
        case expanded
        case transcript
        case unknown
    }

    private let viewModel = LobbyDriverViewModel()
    private let hostLayoutStore = MessagesHostLayoutStore()
    private var requestDismiss: (() -> Void)?
    private var requestExpanded: (() -> Void)?
    private lazy var selectionWatch = SelectionWatchLifecycle<MSConversation> { [weak self] conversation in
        guard let self else {
            return false
        }
        _ = self.viewModel.updateContext(
            conversation: conversation,
            selectedMessage: conversation.selectedMessage,
            trigger: .selectionPoll
        )
        return self.viewModel.shouldMaintainSelectionWatch
    }

    public init() {
        viewModel.onRequestDismiss = { [weak self] in
            self?.requestDismiss?()
        }
        viewModel.onRequestExpanded = { [weak self] in
            self?.requestExpanded?()
        }
    }

    public func configureHostCallbacks(
        requestDismiss: @escaping () -> Void,
        requestExpanded: @escaping () -> Void
    ) {
        self.requestDismiss = requestDismiss
        self.requestExpanded = requestExpanded
    }

    public func makeHostingController() -> UIViewController {
        #if DEBUG
        let rootView = MessagesRootView(
            viewModel: viewModel,
            hostLayoutStore: hostLayoutStore,
            onSettingsTap: { [weak viewModel] in
                viewModel?.recordUXTestingSettingsHookInvocation()
            },
            onRequestExpanded: { [weak self] in
                self?.requestExpanded?()
            }
        )
        #else
        let rootView = MessagesRootView(
            viewModel: viewModel,
            hostLayoutStore: hostLayoutStore,
            onRequestExpanded: { [weak self] in
                self?.requestExpanded?()
            }
        )
        #endif
        return UIHostingController(rootView: rootView)
    }

    public func loadInitialContext(from conversation: MSConversation) {
        guard let selectedMessage = conversation.selectedMessage else {
            return
        }
        refreshContextAndMaybePoll(
            conversation: conversation,
            selectedMessage: selectedMessage,
            trigger: .viewDidLoad
        )
    }

    public func didBecomeActive(with conversation: MSConversation) {
        let route = MessagesLaunchRoute.resolve(
            hasSelectedMessage: conversation.selectedMessage != nil
        )
        if route.requestsExpandedPresentation {
            requestExpanded?()
        }

        switch route {
        case .freshLobby:
            cancelSelectionPolling()
            viewModel.beginFreshLobby(conversation: conversation)
        case .selectedMessage:
            refreshContextAndMaybePoll(
                conversation: conversation,
                selectedMessage: conversation.selectedMessage,
                trigger: .viewDidLoad
            )
        }
    }

    public func didSelect(_ message: MSMessage, conversation: MSConversation) {
        requestExpanded?()
        updateContextAndPolling(
            conversation: conversation,
            selectedMessage: message,
            trigger: .didSelect
        )
    }

    public func didReceive(_ message: MSMessage, conversation: MSConversation) {
        requestExpanded?()
        updateContextAndPolling(
            conversation: conversation,
            selectedMessage: message,
            trigger: .didReceive
        )
    }

    public func cancelSelectionPolling() {
        selectionWatch.cancel()
    }

    public func beginHostTransition() {
        hostLayoutStore.beginTransition()
    }

    public func observeHostLayout(
        boundsSize: CGSize,
        safeAreaInsets: UIEdgeInsets,
        presentationStyle: PresentationStyle
    ) {
        hostLayoutStore.observe(
            measurement(
                boundsSize: boundsSize,
                safeAreaInsets: safeAreaInsets,
                presentationStyle: presentationStyle
            )
        )
    }

    public func completeHostTransition(
        boundsSize: CGSize,
        safeAreaInsets: UIEdgeInsets,
        presentationStyle: PresentationStyle
    ) {
        hostLayoutStore.completeTransition(
            with: measurement(
                boundsSize: boundsSize,
                safeAreaInsets: safeAreaInsets,
                presentationStyle: presentationStyle
            )
        )
    }

    private func updateContextAndPolling(
        conversation: MSConversation,
        selectedMessage: MSMessage,
        trigger: TranscriptSelectionTrigger
    ) {
        let shouldContinuePolling = viewModel.updateContext(
            conversation: conversation,
            selectedMessage: selectedMessage,
            trigger: trigger
        )
        if shouldContinuePolling {
            startSelectionPolling(conversation: conversation)
        } else {
            cancelSelectionPolling()
        }
    }

    private func refreshContextAndMaybePoll(
        conversation: MSConversation,
        selectedMessage: MSMessage?,
        trigger: TranscriptSelectionTrigger
    ) {
        let shouldContinuePolling = viewModel.updateContext(
            conversation: conversation,
            selectedMessage: selectedMessage,
            trigger: trigger
        )
        if shouldContinuePolling || viewModel.shouldMaintainSelectionWatch {
            startSelectionPolling(conversation: conversation)
        } else {
            cancelSelectionPolling()
        }
    }

    private func startSelectionPolling(conversation: MSConversation) {
        selectionWatch.start(watching: conversation)
    }

    private func measurement(
        boundsSize: CGSize,
        safeAreaInsets: UIEdgeInsets,
        presentationStyle: PresentationStyle
    ) -> MessagesHostLayoutStore.Measurement {
        MessagesHostLayoutStore.Measurement(
            boundsSize: boundsSize,
            safeAreaInsets: MessagesHostInsets(
                top: safeAreaInsets.top,
                leading: safeAreaInsets.left,
                bottom: safeAreaInsets.bottom,
                trailing: safeAreaInsets.right
            ),
            presentationStyle: hostPresentationStyle(presentationStyle)
        )
    }

    private func hostPresentationStyle(
        _ style: PresentationStyle
    ) -> MessagesHostPresentationStyle {
        switch style {
        case .compact:
            .compact
        case .expanded:
            .expanded
        case .transcript:
            .transcript
        case .unknown:
            .unknown
        }
    }
}
