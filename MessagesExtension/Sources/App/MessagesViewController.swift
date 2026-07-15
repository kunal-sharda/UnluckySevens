import Messages
import SwiftUI
import UIKit

final class MessagesViewController: MSMessagesAppViewController {
    private let viewModel = LobbyDriverViewModel()
    private let hostResizeShield = MessagesHostResizeShield()
    private var selectionPollingToken: Int = 0
    private let selectionPollingInterval: TimeInterval = 1.5

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.onRequestDismiss = { [weak self] in
            self?.dismiss()
        }

        #if DEBUG
        let rootView = MessagesRootView(
            viewModel: viewModel,
            onSettingsTap: { [weak viewModel] in
                viewModel?.recordUXTestingSettingsHookInvocation()
            }
        )
        #else
        let rootView = MessagesRootView(viewModel: viewModel)
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

        if let conversation = activeConversation {
            refreshContextAndMaybePoll(
                conversation: conversation,
                selectedMessage: conversation.selectedMessage,
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
    }

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        requestExpandedPresentationIfNeeded()
        refreshContextAndMaybePoll(
            conversation: conversation,
            selectedMessage: conversation.selectedMessage,
            trigger: .viewDidLoad
        )
    }

    override func didBecomeActive(with conversation: MSConversation) {
        super.didBecomeActive(with: conversation)
        requestExpandedPresentationIfNeeded()
        refreshContextAndMaybePoll(
            conversation: conversation,
            selectedMessage: conversation.selectedMessage,
            trigger: .viewDidLoad
        )
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

    private var resizeGrabberExclusionHeight: CGFloat {
        max(36, view.safeAreaInsets.top + 12)
    }
}
