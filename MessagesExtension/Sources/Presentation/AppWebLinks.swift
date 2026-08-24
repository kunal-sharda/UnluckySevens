import Foundation

enum AppWebLinks {
    static let productURL = validatedURL("https://ksharda.me/unluckysevens")
    static let privacyPolicyURL = validatedURL("https://ksharda.me/unluckysevens/privacy")

    static let messageHost = "ksharda.me"
    static let messagePath = "/unluckysevens/msg"

    private static func validatedURL(_ value: String) -> URL {
        guard let url = URL(string: value) else {
            preconditionFailure("Invalid application URL: \(value)")
        }
        return url
    }
}
