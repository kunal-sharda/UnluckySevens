import Messages
@_spi(MessagesHost) import MessagesExtensionSupport
import UIKit

final class MessagesViewController: MSMessagesAppViewController {
    private let runtime = MessagesExtensionHostRuntime()
    private let hostResizeShield = MessagesHostResizeShield()
    #if DEBUG
    private weak var debugHostingView: UIView?
    private let debugGeometry = UILabel()
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()

        runtime.configureHostCallbacks(
            requestDismiss: { [weak self] in
                self?.dismiss()
            },
            requestExpanded: { [weak self] in
                self?.requestExpandedPresentationIfNeeded()
            }
        )

        let hostingController = runtime.makeHostingController()
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        #if DEBUG
        debugHostingView = hostingController.view
        if UserDefaults.standard.string(forKey: "uls.debug.launchFixtureID")?.hasPrefix("preview-") == true {
            debugGeometry.frame = CGRect(x: 0, y: 40, width: 1, height: 1)
            debugGeometry.textColor = .clear
            debugGeometry.isUserInteractionEnabled = false
            debugGeometry.isAccessibilityElement = true
            debugGeometry.accessibilityIdentifier = "uls.host.uikitGeometry"
            debugGeometry.accessibilityLabel = "UIKit host geometry"
            view.addSubview(debugGeometry)
        }
        #endif

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        if let conversation = activeConversation {
            runtime.loadInitialContext(from: conversation)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        hostResizeShield.attach(
            to: view,
            topExclusionHeight: resizeGrabberExclusionHeight
        )
        observeCurrentHostLayout()
        #if DEBUG
        if let child = debugHostingView {
            debugGeometry.accessibilityValue = "rootBounds=\(view.bounds); rootWindow=\(view.convert(view.bounds, to: nil)); rootSafe=\(view.safeAreaInsets); childBounds=\(child.bounds); childWindow=\(child.convert(child.bounds, to: nil)); childSafe=\(child.safeAreaInsets); center=\(child.center); transform=\(child.transform); window=\(String(describing: view.window)); constraints=\(view.constraints)"
        }
        #endif
    }

    override func didBecomeActive(with conversation: MSConversation) {
        super.didBecomeActive(with: conversation)
        runtime.didBecomeActive(with: conversation)
    }

    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        super.didSelect(message, conversation: conversation)
        runtime.didSelect(message, conversation: conversation)
    }

    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        super.didReceive(message, conversation: conversation)
        runtime.didReceive(message, conversation: conversation)
    }

    override func willResignActive(with conversation: MSConversation) {
        super.willResignActive(with: conversation)
        runtime.willResignActive()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        runtime.cancelSelectionPolling()
    }

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.willTransition(to: presentationStyle)
        runtime.beginHostTransition()
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        completeHostTransition(presentationStyle: presentationStyle)
    }

    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        runtime.beginHostTransition()
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.completeHostTransition()
        }
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

    private func observeCurrentHostLayout() {
        runtime.observeHostLayout(
            boundsSize: view.bounds.size,
            safeAreaInsets: view.safeAreaInsets,
            presentationStyle: hostPresentationStyle(presentationStyle)
        )
    }

    private func completeHostTransition(
        presentationStyle resolvedPresentationStyle: MSMessagesAppPresentationStyle? = nil
    ) {
        runtime.completeHostTransition(
            boundsSize: view.bounds.size,
            safeAreaInsets: view.safeAreaInsets,
            presentationStyle: hostPresentationStyle(
                resolvedPresentationStyle ?? presentationStyle
            )
        )
    }

    private func hostPresentationStyle(
        _ style: MSMessagesAppPresentationStyle
    ) -> MessagesExtensionHostRuntime.PresentationStyle {
        switch style {
        case .compact:
            .compact
        case .expanded:
            .expanded
        case .transcript:
            .transcript
        @unknown default:
            .unknown
        }
    }
}
