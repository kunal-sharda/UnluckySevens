struct TemporaryDiagnosticsConfig: Equatable {
    let isEnabled: Bool

    // Stage 13 gates the temporary host/transport diagnostics off for release-readiness.
    static let live = TemporaryDiagnosticsConfig(isEnabled: false)
    static let disabled = TemporaryDiagnosticsConfig(isEnabled: false)
}
