struct InvitePublicationHostContext {
    private(set) var conversationIdentity: ObjectIdentifier?

    mutating func adopt(conversationIdentity newIdentity: ObjectIdentifier?) -> Bool {
        let changed = conversationIdentity != nil && conversationIdentity != newIdentity
        conversationIdentity = newIdentity
        return changed
    }
}
