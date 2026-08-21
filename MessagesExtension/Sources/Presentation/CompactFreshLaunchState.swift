struct CompactFreshLaunchState: Equatable {
    private(set) var visibleToken: Int?
    private var nextToken = 0

    mutating func begin() {
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
    }
}
