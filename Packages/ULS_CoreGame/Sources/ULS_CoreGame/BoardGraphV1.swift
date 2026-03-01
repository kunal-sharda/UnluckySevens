import Foundation

public typealias TileID = Int
public typealias NodeID = Int
public typealias EdgeID = Int

public struct EdgeV1: Codable, Equatable {
    public let a: NodeID
    public let b: NodeID

    public init(a: NodeID, b: NodeID) {
        self.a = a
        self.b = b
    }
}

public struct TileV1: Codable, Equatable {
    public let nodes: [NodeID]
    public let edges: [EdgeID]

    public init(nodes: [NodeID], edges: [EdgeID]) {
        self.nodes = nodes
        self.edges = edges
    }
}

public enum ResourceV1: String, Codable, Equatable, CaseIterable {
    case wood
    case brick
    case sheep
    case wheat
    case ore
}

public enum PortKindV1: Codable, Equatable {
    case threeToOne
    case twoToOne(ResourceV1)

    private enum CodingKeys: String, CodingKey {
        case kind
        case resource
    }

    private enum Kind: String, Codable {
        case threeToOne
        case twoToOne
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)

        switch kind {
        case .threeToOne:
            self = .threeToOne
        case .twoToOne:
            let resource = try container.decode(ResourceV1.self, forKey: .resource)
            self = .twoToOne(resource)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .threeToOne:
            try container.encode(Kind.threeToOne, forKey: .kind)
        case let .twoToOne(resource):
            try container.encode(Kind.twoToOne, forKey: .kind)
            try container.encode(resource, forKey: .resource)
        }
    }
}

public struct PortV1: Codable, Equatable {
    public let edge: EdgeID
    public let kind: PortKindV1

    public init(edge: EdgeID, kind: PortKindV1) {
        self.edge = edge
        self.kind = kind
    }
}

public struct BoardGraphV1: Codable, Equatable {
    public let tiles: [TileV1]
    public let nodesCount: Int
    public let edges: [EdgeV1]
    public let ports: [PortV1]
    public let robber: TileID

    public init(
        tiles: [TileV1],
        nodesCount: Int,
        edges: [EdgeV1],
        ports: [PortV1],
        robber: TileID
    ) {
        self.tiles = tiles
        self.nodesCount = nodesCount
        self.edges = edges
        self.ports = ports
        self.robber = robber
    }

    public func edges(incidentTo node: NodeID) -> [EdgeID] {
        edges.enumerated()
            .filter { _, edge in edge.a == node || edge.b == node }
            .map(\.offset)
    }

    public func nodes(adjacentTo node: NodeID) -> [NodeID] {
        let adjacent = edges(incidentTo: node).map { edgeID -> NodeID in
            let edge = edges[edgeID]
            return edge.a == node ? edge.b : edge.a
        }

        return Array(Set(adjacent)).sorted()
    }

    public func tiles(adjacentToNode node: NodeID) -> [TileID] {
        tiles.enumerated()
            .filter { _, tile in tile.nodes.contains(node) }
            .map(\.offset)
    }

    public func tiles(adjacentToEdge edge: EdgeID) -> [TileID] {
        tiles.enumerated()
            .filter { _, tile in tile.edges.contains(edge) }
            .map(\.offset)
    }

    public func isCoastal(edge: EdgeID) -> Bool {
        tiles(adjacentToEdge: edge).count == 1
    }

    public func portKind(at node: NodeID) -> PortKindV1? {
        for port in ports {
            let edge = edges[port.edge]
            if edge.a == node || edge.b == node {
                return port.kind
            }
        }

        return nil
    }
}
