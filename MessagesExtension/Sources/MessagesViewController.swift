import Messages
import UIKit
import ULS_Transport

final class MessagesViewController: MSMessagesAppViewController {
    private let summaryPayloadPrefix = "ulsdbg:"

    private enum SendState: String {
        case idle
        case sending
        case sent
        case failed
    }

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var sendButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Send Debug Bubble"

        let button = UIButton(type: .system)
        button.configuration = config
        button.addTarget(self, action: #selector(sendDebugBubble), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [statusLabel, sendButton])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var sendState: SendState = .idle
    private var selectionStatus: String = "none"
    private var selectedURLStatus: String = "unknown"
    private var payloadSourceStatus: String = "-"
    private var decodeStatus: String = "No message selected"
    private var lastSentDebugId: String = "-"
    private var lastSentTimestamp: String = "-"
    private var lastSelectedURL: String = "-"
    private var selectionPollingToken: Int = 0
    private var decodedCurrentSelection: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        updateStatus(from: activeConversation?.selectedMessage)
        renderStatus()
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
        cancelSelectionPolling()
        updateStatus(from: message)
        renderStatus()
    }

    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        super.didReceive(message, conversation: conversation)
        cancelSelectionPolling()
        updateStatus(from: message)
        renderStatus()
    }

    @objc
    private func sendDebugBubble() {
        guard let conversation = activeConversation else {
            sendState = .failed
            decodeStatus = "No active conversation."
            renderStatus()
            return
        }

        sendState = .sending
        renderStatus()

        let payload = DebugPayload(
            timestamp: Int(Date().timeIntervalSince1970),
            debugId: UUID().uuidString
        )
        let encodedPayload = encodeDebugPayload(payload)
        guard !encodedPayload.isEmpty else {
            sendState = .failed
            decodeStatus = "Could not encode debug payload."
            renderStatus()
            return
        }

        var components = URLComponents()
        components.scheme = "unluckysevens"
        components.host = "msg"
        components.queryItems = [URLQueryItem(name: "payload", value: encodedPayload)]

        guard let url = components.url else {
            sendState = .failed
            decodeStatus = "Could not build debug bubble URL."
            renderStatus()
            return
        }

        let message = MSMessage(session: MSSession())
        message.url = url

        let layout = MSMessageTemplateLayout()
        layout.caption = "Unlucky Sevens Debug v1"
        layout.subcaption = "debugId: \(String(payload.debugId.prefix(8)))"
        layout.trailingSubcaption = "ts: \(payload.timestamp)"
        message.layout = layout
        message.summaryText = "\(summaryPayloadPrefix)\(encodedPayload)"

        lastSentDebugId = payload.debugId
        lastSentTimestamp = String(payload.timestamp)

        conversation.insert(message) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.sendState = .failed
                    self?.decodeStatus = "Failed to send bubble: \(error.localizedDescription)"
                } else {
                    self?.sendState = .sent
                    self?.decodeStatus = "Debug bubble sent. Tap bubble in transcript to decode."
                }
                self?.renderStatus()
            }
        }
    }

    private func updateStatus(from message: MSMessage?) {
        guard let message else {
            selectionStatus = "none"
            selectedURLStatus = "not provided"
            payloadSourceStatus = "-"
            decodeStatus = "No message selected"
            decodedCurrentSelection = false
            lastSelectedURL = "-"
            return
        }

        if let url = message.url {
            updateStatus(from: url)
            return
        }

        if let summaryPayload = extractPayloadFromSummaryText(message: message) {
            selectionStatus = "message selected"
            selectedURLStatus = "missing"
            lastSelectedURL = "-"
            updateStatus(fromPayloadValue: summaryPayload, source: "summaryText")
            return
        }

        selectionStatus = "message selected"
        selectedURLStatus = "missing"
        payloadSourceStatus = "-"
        decodeStatus = "Selected message has no URL."
        decodedCurrentSelection = false
        lastSelectedURL = "-"
    }

    private func updateStatus(from url: URL?) {
        guard let url else {
            selectionStatus = "none"
            selectedURLStatus = "not provided"
            payloadSourceStatus = "-"
            decodeStatus = "No message selected"
            decodedCurrentSelection = false
            lastSelectedURL = "-"
            return
        }

        selectionStatus = "message selected"
        selectedURLStatus = "provided"
        lastSelectedURL = truncate(url.absoluteString, limit: 140)

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let payloadValue = components.queryItems?.first(where: { $0.name == "payload" })?.value,
              !payloadValue.isEmpty else {
            selectionStatus = "message selected without payload"
            payloadSourceStatus = "url"
            decodeStatus = "Selected message URL has no payload query."
            decodedCurrentSelection = false
            return
        }

        updateStatus(fromPayloadValue: payloadValue, source: "url")
    }

    private func updateStatus(fromPayloadValue payloadValue: String, source: String) {
        payloadSourceStatus = source
        do {
            let payload = try decodeDebugPayload(from: payloadValue)
            decodeStatus = "Decoded: type=\(payload.type), v=\(payload.v), timestamp=\(payload.timestamp), debugId=\(payload.debugId)"
            decodedCurrentSelection = true
        } catch {
            decodeStatus = "Payload decode failed: \(friendlyErrorMessage(for: error))"
            decodedCurrentSelection = false
        }
    }

    private func extractPayloadFromSummaryText(message: MSMessage) -> String? {
        guard let summaryText = message.summaryText,
              summaryText.hasPrefix(summaryPayloadPrefix) else {
            return nil
        }

        let payloadStart = summaryText.index(summaryText.startIndex, offsetBy: summaryPayloadPrefix.count)
        let payload = String(summaryText[payloadStart...])
        return payload.isEmpty ? nil : payload
    }

    private func startSelectionPolling(conversation: MSConversation) {
        cancelSelectionPolling()
        let token = selectionPollingToken
        let delays: [TimeInterval] = [0.0, 0.2, 0.6, 1.2]

        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.selectionPollingToken == token else { return }
                if self.decodedCurrentSelection {
                    return
                }

                self.updateStatus(from: conversation.selectedMessage)
                self.renderStatus()

                if self.decodedCurrentSelection {
                    self.cancelSelectionPolling()
                }
            }
        }
    }

    private func cancelSelectionPolling() {
        selectionPollingToken += 1
    }

    private func renderStatus() {
        statusLabel.text = """
        Send: \(sendState.rawValue)
        Selection: \(selectionStatus)
        selectedMessage.url: \(selectedURLStatus)
        Payload source: \(payloadSourceStatus)
        Decode: \(decodeStatus)

        Last sent debugId: \(lastSentDebugId)
        Last sent timestamp: \(lastSentTimestamp)
        Last selected URL: \(lastSelectedURL)
        """
    }

    private func truncate(_ value: String, limit: Int) -> String {
        guard value.count > limit else { return value }
        return String(value.prefix(limit)) + "..."
    }

    private func friendlyErrorMessage(for error: Error) -> String {
        if let codecError = error as? DebugPayloadCodecError {
            return codecError.localizedDescription
        }

        return error.localizedDescription
    }
}
