struct CompactFreshLaunchState: Equatable {
    private(set) var visibleToken: Int?
    private var nextToken = 0
    private var hasPreparedCurrentActivation = false

    @discardableResult
    mutating func begin() -> Bool {
        guard !hasPreparedCurrentActivation else { return false }
        hasPreparedCurrentActivation = true
        nextToken &+= 1
        visibleToken = nextToken
        return true
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
