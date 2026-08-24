struct CompactFreshLaunchState: Equatable {
    private(set) var visibleToken: Int?
    private var nextToken = 0
    private var hasPreparedCurrentActivation = false

    mutating func begin() {
        guard !hasPreparedCurrentActivation else { return }
        hasPreparedCurrentActivation = true
        nextToken &+= 1
        visibleToken = nextToken
    }

    @discardableResult
    mutating func consume() -> Bool {
        guard visibleToken != nil else { return false }
        visibleToken = nil
        return true
    }

    mutating func dismiss() {
        visibleToken = nil
        hasPreparedCurrentActivation = false
    }

    mutating func endActivation() {
        visibleToken = nil
        hasPreparedCurrentActivation = false
    }
}
