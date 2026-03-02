import Foundation

public struct DevCardInventoryV1: Codable, Equatable {
    public let knight: Int
    public let monopoly: Int
    public let yearOfPlenty: Int
    public let roadBuilding: Int
    public let victoryPoint: Int

    public init(
        knight: Int = 0,
        monopoly: Int = 0,
        yearOfPlenty: Int = 0,
        roadBuilding: Int = 0,
        victoryPoint: Int = 0
    ) {
        self.knight = knight
        self.monopoly = monopoly
        self.yearOfPlenty = yearOfPlenty
        self.roadBuilding = roadBuilding
        self.victoryPoint = victoryPoint
    }

    public static let zero = DevCardInventoryV1()

    public var totalCount: Int {
        knight + monopoly + yearOfPlenty + roadBuilding + victoryPoint
    }

    public func count(for card: DevCardV1) -> Int {
        switch card {
        case .knight:
            return knight
        case .monopoly:
            return monopoly
        case .yearOfPlenty:
            return yearOfPlenty
        case .roadBuilding:
            return roadBuilding
        case .victoryPoint:
            return victoryPoint
        }
    }

    public func adding(_ amount: Int, card: DevCardV1) -> DevCardInventoryV1 {
        switch card {
        case .knight:
            return DevCardInventoryV1(
                knight: knight + amount,
                monopoly: monopoly,
                yearOfPlenty: yearOfPlenty,
                roadBuilding: roadBuilding,
                victoryPoint: victoryPoint
            )
        case .monopoly:
            return DevCardInventoryV1(
                knight: knight,
                monopoly: monopoly + amount,
                yearOfPlenty: yearOfPlenty,
                roadBuilding: roadBuilding,
                victoryPoint: victoryPoint
            )
        case .yearOfPlenty:
            return DevCardInventoryV1(
                knight: knight,
                monopoly: monopoly,
                yearOfPlenty: yearOfPlenty + amount,
                roadBuilding: roadBuilding,
                victoryPoint: victoryPoint
            )
        case .roadBuilding:
            return DevCardInventoryV1(
                knight: knight,
                monopoly: monopoly,
                yearOfPlenty: yearOfPlenty,
                roadBuilding: roadBuilding + amount,
                victoryPoint: victoryPoint
            )
        case .victoryPoint:
            return DevCardInventoryV1(
                knight: knight,
                monopoly: monopoly,
                yearOfPlenty: yearOfPlenty,
                roadBuilding: roadBuilding,
                victoryPoint: victoryPoint + amount
            )
        }
    }

    public func addingOne(card: DevCardV1) -> DevCardInventoryV1 {
        adding(1, card: card)
    }

    public func subtractingOne(card: DevCardV1) -> DevCardInventoryV1 {
        adding(-1, card: card)
    }

    internal func canonicalJSONValue() -> [String: Any] {
        [
            "knight": knight,
            "monopoly": monopoly,
            "yearOfPlenty": yearOfPlenty,
            "roadBuilding": roadBuilding,
            "victoryPoint": victoryPoint,
        ]
    }
}
