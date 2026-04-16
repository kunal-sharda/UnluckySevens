struct TemporaryDiagnosticsConfig: Equatable {
    let isEnabled: Bool

    static let live = TemporaryDiagnosticsConfig(isEnabled: true)
    static let disabled = TemporaryDiagnosticsConfig(isEnabled: false)
}
