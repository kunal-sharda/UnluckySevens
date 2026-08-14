import CoreGraphics

struct MessagesHostInsets: Equatable {
    let top: CGFloat
    let leading: CGFloat
    let bottom: CGFloat
    let trailing: CGFloat

    static let zero = Self(top: 0, leading: 0, bottom: 0, trailing: 0)
}
