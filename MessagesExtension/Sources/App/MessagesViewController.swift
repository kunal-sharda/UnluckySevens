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

        viewModel.updateContext(
            conversation: activeConversation,
            selectedMessage: activeConversation?.selectedMessage,
            trigger: .viewDidLoad
        )
    }

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        startSelectionPolling(conversation: conversation)
    }

    override func didBecomeActive(with conversation: MSConversation) {
        super.didBecomeActive(with: conversation)
        startSelectionPolling(conversation: conversation)
    }

    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        super.didSelect(message, conversation: conversation)
        viewModel.updateContext(
            conversation: conversation,
            selectedMessage: message,
            trigger: .didSelect
        )
        startSelectionPolling(conversation: conversation)
    }

    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        super.didReceive(message, conversation: conversation)
        viewModel.updateContext(
            conversation: conversation,
            selectedMessage: message,
            trigger: .didReceive
        )
        startSelectionPolling(conversation: conversation)
    }

    private func startSelectionPolling(conversation: MSConversation) {
        cancelSelectionPolling()
        let token = selectionPollingToken
        let delays: [TimeInterval] = [0.0, 0.2, 0.6, 1.2, 2.4, 4.0, 6.0]

        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.selectionPollingToken == token else { return }

                self.viewModel.updateContext(
                    conversation: conversation,
                    selectedMessage: conversation.selectedMessage,
                    trigger: .selectionPoll
                )
            }
        }
    }

    private func cancelSelectionPolling() {
        selectionPollingToken += 1
    }
}
