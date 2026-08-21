import Messages
import SwiftUI
import UIKit

final class MessagesViewController: MSMessagesAppViewController {
    private let viewModel = LobbyDriverViewModel()
    private let hostLayoutStore = MessagesHostLayoutStore()
    private let hostResizeShield = MessagesHostResizeShield()
    private var selectionPollingToken: Int = 0
    private let selectionPollingInterval: TimeInterval = 1.5

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.onRequestDismiss = { [weak self] in
            self?.dismiss()
        }
        viewModel.onRequestExpanded = { [weak self] in
            self?.requestExpandedPresentationIfNeeded()
        }

        #if DEBUG
        let rootView = MessagesRootView(
            viewModel: viewModel,
            hostLayoutStore: hostLayoutStore,
            onSettingsTap: { [weak viewModel] in
                viewModel?.recordUXTestingSettingsHookInvocation()
            },
            onRequestExpanded: { [weak self] in
                self?.requestExpandedPresentationIfNeeded()
            }
        )
        #else
        let rootView = MessagesRootView(
            viewModel: viewModel,
            hostLayoutStore: hostLayoutStore,
            onRequestExpanded: { [weak self] in
                self?.requestExpandedPresentationIfNeeded()
            }
        )
        #endif
        let hostingController = UIHostingController(rootView: rootView)

        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        if let conversation = activeConversation,
           let selectedMessage = conversation.selectedMessage {
            refreshContextAndMaybePoll(
                conversation: conversation,
                selectedMessage: selectedMessage,
                trigger: .viewDidLoad
            )
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        hostResizeShield.attach(
            to: view,
            topExclusionHeight: resizeGrabberExclusionHeight
        )
        hostLayoutStore.observe(currentHostMeasurement())
    }

    override func didBecomeActive(with conversation: MSConversation) {
        super.didBecomeActive(with: conversation)
        activateRoute(for: conversation)
    }

    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        super.didSelect(message, conversation: conversation)
        requestExpandedPresentationIfNeeded()
        let shouldContinuePolling = viewModel.updateContext(
            conversation: conversation,
            selectedMessage: message,
            trigger: .didSelect
        )
        if shouldContinuePolling {
            startSelectionPolling(conversation: conversation)
        } else {
            cancelSelectionPolling()
        }
    }

    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        super.didReceive(message, conversation: conversation)
        requestExpandedPresentationIfNeeded()
        let shouldContinuePolling = viewModel.updateContext(
            conversation: conversation,
            selectedMessage: message,
            trigger: .didReceive
        )
        if shouldContinuePolling {
            startSelectionPolling(conversation: conversation)
        } else {
            cancelSelectionPolling()
        }
    }

    override func willResignActive(with conversation: MSConversation) {
        super.willResignActive(with: conversation)
        cancelSelectionPolling()
    }

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.willTransition(to: presentationStyle)
        hostLayoutStore.beginTransition()
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        hostLayoutStore.completeTransition(
            with: currentHostMeasurement(presentationStyle: presentationStyle)
        )
    }

    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        hostLayoutStore.beginTransition()
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            self.hostLayoutStore.completeTransition(with: self.currentHostMeasurement())
        }
    }

    private func startSelectionPolling(conversation: MSConversation) {
        cancelSelectionPolling()
        let token = selectionPollingToken
        scheduleSelectionPoll(
            conversation: conversation,
            token: token,
            delay: 0.2
        )
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

    private func scheduleSelectionPoll(
        conversation: MSConversation,
        token: Int,
        delay: TimeInterval
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.selectionPollingToken == token else { return }

            _ = self.viewModel.updateContext(
                conversation: conversation,
                selectedMessage: conversation.selectedMessage,
                trigger: .selectionPoll
            )

            guard self.selectionPollingToken == token, self.viewModel.shouldMaintainSelectionWatch else {
                self.cancelSelectionPolling()
                return
            }

            self.scheduleSelectionPoll(
                conversation: conversation,
                token: token,
                delay: self.selectionPollingInterval
            )
        }
    }

    private func cancelSelectionPolling() {
        selectionPollingToken += 1
    }

    private func requestExpandedPresentationIfNeeded() {
        guard presentationStyle != .expanded else {
            return
        }

        requestPresentationStyle(.expanded)
    }

    private func activateRoute(for conversation: MSConversation) {
        let route = MessagesLaunchRoute.resolve(
            hasSelectedMessage: conversation.selectedMessage != nil
        )
        if route.requestsExpandedPresentation {
            requestExpandedPresentationIfNeeded()
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

    private var resizeGrabberExclusionHeight: CGFloat {
        max(36, view.safeAreaInsets.top + 12)
    }

    private func currentHostMeasurement(
        presentationStyle resolvedPresentationStyle: MSMessagesAppPresentationStyle? = nil
    ) -> MessagesHostLayoutStore.Measurement {
        let insets = view.safeAreaInsets
        return MessagesHostLayoutStore.Measurement(
            boundsSize: view.bounds.size,
            safeAreaInsets: MessagesHostInsets(
                top: insets.top,
                leading: insets.left,
                bottom: insets.bottom,
                trailing: insets.right
            ),
            presentationStyle: hostPresentationStyle(
                resolvedPresentationStyle ?? presentationStyle
            )
        )
    }

    private func hostPresentationStyle(
        _ style: MSMessagesAppPresentationStyle
    ) -> MessagesHostPresentationStyle {
        switch style {
        case .compact:
            return .compact
        case .expanded:
            return .expanded
        case .transcript:
            return .transcript
        @unknown default:
            return .unknown
        }
    }
}
