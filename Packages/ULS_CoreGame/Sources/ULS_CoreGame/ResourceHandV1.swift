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
    public static let standardBank = ResourceHandV1(wood: 19, brick: 19, sheep: 19, wheat: 19, ore: 19)

    public var totalCount: Int {
        wood + brick + sheep + wheat + ore
    }

    public func count(for resource: ResourceV1) -> Int {
        switch resource {
        case .wood:
            return wood
        case .brick:
            return brick
        case .sheep:
            return sheep
        case .wheat:
            return wheat
        case .ore:
            return ore
        case .desert:
            return 0
        }
    }

    public func adding(_ amount: Int, for resource: ResourceV1) -> ResourceHandV1 {
        switch resource {
        case .wood:
            return ResourceHandV1(
                wood: wood + amount,
                brick: brick,
                sheep: sheep,
                wheat: wheat,
                ore: ore
            )
        case .brick:
            return ResourceHandV1(
                wood: wood,
                brick: brick + amount,
                sheep: sheep,
                wheat: wheat,
                ore: ore
            )
        case .sheep:
            return ResourceHandV1(
                wood: wood,
                brick: brick,
                sheep: sheep + amount,
                wheat: wheat,
                ore: ore
            )
        case .wheat:
            return ResourceHandV1(
                wood: wood,
                brick: brick,
                sheep: sheep,
                wheat: wheat + amount,
                ore: ore
            )
        case .ore:
            return ResourceHandV1(
                wood: wood,
                brick: brick,
                sheep: sheep,
                wheat: wheat,
                ore: ore + amount
            )
        case .desert:
            return self
        }
    }

    public func subtracting(_ amount: Int, for resource: ResourceV1) -> ResourceHandV1 {
        adding(-amount, for: resource)
    }

    public func addingOne(for resource: ResourceV1) -> ResourceHandV1 {
        adding(1, for: resource)
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
