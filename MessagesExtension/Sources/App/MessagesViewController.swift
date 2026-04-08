import Messages
import SwiftUI
import UIKit

final class MessagesViewController: MSMessagesAppViewController {
    private let viewModel = LobbyDriverViewModel()
    private var selectionPollingToken: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        let rootView = MessagesRootView(viewModel: viewModel)
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

    private func startSelectionPolling(conversation: MSConversation) {
        cancelSelectionPolling()
        let token = selectionPollingToken
        let delays: [TimeInterval] = [0.2, 0.6, 1.2, 2.4]

        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.selectionPollingToken == token else { return }

                let shouldContinuePolling = self.viewModel.updateContext(
                    conversation: conversation,
                    selectedMessage: conversation.selectedMessage,
                    trigger: .selectionPoll
                )
                if !shouldContinuePolling {
                    self.cancelSelectionPolling()
                }
            }
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
        if shouldContinuePolling {
            startSelectionPolling(conversation: conversation)
        } else {
            cancelSelectionPolling()
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
}
