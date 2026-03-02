import Foundation

public struct ResourceHandV1: Codable, Equatable {
    public let wood: Int
    public let brick: Int
    public let sheep: Int
    public let wheat: Int
    public let ore: Int

    public init(
        wood: Int = 0,
        brick: Int = 0,
        sheep: Int = 0,
        wheat: Int = 0,
        ore: Int = 0
    ) {
        self.wood = wood
        self.brick = brick
        self.sheep = sheep
        self.wheat = wheat
        self.ore = ore
    }

    public static let zero = ResourceHandV1()

    public func addingOne(for resource: ResourceV1) -> ResourceHandV1 {
        switch resource {
        case .wood:
            return ResourceHandV1(wood: wood + 1, brick: brick, sheep: sheep, wheat: wheat, ore: ore)
        case .brick:
            return ResourceHandV1(wood: wood, brick: brick + 1, sheep: sheep, wheat: wheat, ore: ore)
        case .sheep:
            return ResourceHandV1(wood: wood, brick: brick, sheep: sheep + 1, wheat: wheat, ore: ore)
        case .wheat:
            return ResourceHandV1(wood: wood, brick: brick, sheep: sheep, wheat: wheat + 1, ore: ore)
        case .ore:
            return ResourceHandV1(wood: wood, brick: brick, sheep: sheep, wheat: wheat, ore: ore + 1)
        case .desert:
            return self
        }
    }

    internal func canonicalJSONValue() -> [String: Any] {
        [
            "wood": wood,
            "brick": brick,
            "sheep": sheep,
            "wheat": wheat,
            "ore": ore,
        ]
    }
}
