import Foundation

public enum StandardBoardTopologyV1 {
    public static func standard() -> BoardGraphV1 {
        let geometry = buildGeometry()
        let portEdges = canonicalFramePortEdges(from: geometry)
        let portKinds: [PortKindV1] = [
            .threeToOne,
            .twoToOne(.wood),
            .threeToOne,
            .twoToOne(.brick),
            .threeToOne,
            .twoToOne(.sheep),
            .threeToOne,
            .twoToOne(.wheat),
            .twoToOne(.ore),
        ]

        let ports = zip(portEdges, portKinds).map { edge, kind in
            PortV1(edge: edge, kind: kind)
        }

        return BoardGraphV1(
            tiles: geometry.tiles,
            nodesCount: geometry.nodeCoordinates.count,
            edges: geometry.edges,
            ports: ports,
            robber: 0
        )
    }

    public static func renderGeometry() -> BoardRenderGeometryV1 {
        let geometry = buildGeometry()

        let nodePositions = geometry.nodeCoordinates.map {
            BoardRenderPointV1(
                x: Double($0.u),
                y: Double($0.w) * 0.5
            )
        }

        let tileCenters = geometry.tiles.map { tile -> BoardRenderPointV1 in
            let points = tile.nodes.map { nodePositions[$0] }
            let count = Double(points.count)
            let x = points.reduce(0.0) { $0 + $1.x } / count
            let y = points.reduce(0.0) { $0 + $1.y } / count
            return BoardRenderPointV1(x: x, y: y)
        }

        return BoardRenderGeometryV1(
            tileCenters: tileCenters,
            nodePositions: nodePositions
        )
    }

    internal static func canonicalFramePortEdgesForStandard() -> [EdgeID] {
        canonicalFramePortEdges(from: buildGeometry())
    }

    private static func buildGeometry() -> Geometry {
        var nodesByPoint: [LatticePoint: NodeID] = [:]
        var nodeCoordinates: [LatticePoint] = []
        var edgesByNodes: [EdgeKey: EdgeID] = [:]
        var edges: [EdgeV1] = []
        var tiles: [TileV1] = []

        for (q, r) in tileCoordinates() {
            let centerU = (2 * q) + r
            let centerW = 3 * r

            var tileNodes: [NodeID] = []
            for offset in cornerOffsets {
                let point = LatticePoint(u: centerU + offset.u, w: centerW + offset.w)
                if let existing = nodesByPoint[point] {
                    tileNodes.append(existing)
                } else {
                    let next = nodeCoordinates.count
                    nodesByPoint[point] = next
                    nodeCoordinates.append(point)
                    tileNodes.append(next)
                }
            }

            var tileEdges: [EdgeID] = []
            for index in 0..<6 {
                let edgeKey = EdgeKey(tileNodes[index], tileNodes[(index + 1) % 6])
                if let existing = edgesByNodes[edgeKey] {
                    tileEdges.append(existing)
                } else {
                    let next = edges.count
                    edgesByNodes[edgeKey] = next
                    edges.append(EdgeV1(a: edgeKey.a, b: edgeKey.b))
                    tileEdges.append(next)
                }
            }

            tiles.append(TileV1(nodes: tileNodes, edges: tileEdges))
        }

        var edgeToTiles = Array(repeating: [TileID](), count: edges.count)
        for (tileID, tile) in tiles.enumerated() {
            for edgeID in tile.edges {
                edgeToTiles[edgeID].append(tileID)
            }
        }

        precondition(tiles.count == 19, "Standard topology must produce 19 tiles.")
        precondition(nodeCoordinates.count == 54, "Standard topology must produce 54 nodes.")
        precondition(edges.count == 72, "Standard topology must produce 72 edges.")

        return Geometry(
            tiles: tiles,
            edges: edges,
            nodeCoordinates: nodeCoordinates,
            edgeToTiles: edgeToTiles
        )
    }

    private static func canonicalFramePortEdges(from geometry: Geometry) -> [EdgeID] {
        let coastalEdges = geometry.edgeToTiles.enumerated()
            .filter { _, adjacent in adjacent.count == 1 }
            .map(\.offset)
            .sorted()

        precondition(coastalEdges.count == 30, "Standard topology must have 30 coastal edges.")

        var nodeToCoastalEdges: [NodeID: [EdgeID]] = [:]
        for edgeID in coastalEdges {
            let edge = geometry.edges[edgeID]
            nodeToCoastalEdges[edge.a, default: []].append(edgeID)
            nodeToCoastalEdges[edge.b, default: []].append(edgeID)
        }

        func neighbors(of edgeID: EdgeID) -> [EdgeID] {
            let edge = geometry.edges[edgeID]
            var adjacent: Set<EdgeID> = []

            for nodeID in [edge.a, edge.b] {
                for candidate in nodeToCoastalEdges[nodeID, default: []] where candidate != edgeID {
                    adjacent.insert(candidate)
                }
            }

            return Array(adjacent).sorted()
        }

        func midpointSums(for edgeID: EdgeID) -> (sumU: Int, sumW: Int) {
            let edge = geometry.edges[edgeID]
            let a = geometry.nodeCoordinates[edge.a]
            let b = geometry.nodeCoordinates[edge.b]
            return (a.u + b.u, a.w + b.w)
        }

        let startEdge = coastalEdges.min { lhs, rhs in
            let left = midpointSums(for: lhs)
            let right = midpointSums(for: rhs)
            if left.sumW != right.sumW { return left.sumW > right.sumW }
            if left.sumU != right.sumU { return left.sumU < right.sumU }
            return lhs < rhs
        }!

        let startNeighbors = neighbors(of: startEdge)
        precondition(startNeighbors.count == 2, "A coastal edge should have exactly two coastal neighbors.")

        var cycle: [EdgeID] = [startEdge, startNeighbors[0]]
        var previous = startEdge
        var current = startNeighbors[0]

        while true {
            let nextCandidates = neighbors(of: current).filter { $0 != previous }.sorted()
            guard let next = nextCandidates.first else {
                preconditionFailure("Failed to find next coastal edge while building perimeter cycle.")
            }

            if next == startEdge {
                break
            }

            cycle.append(next)
            previous = current
            current = next

            precondition(
                cycle.count <= coastalEdges.count,
                "Perimeter cycle exceeded expected coastal edge count."
            )
        }

        precondition(cycle.count == coastalEdges.count, "Perimeter cycle must include all coastal edges exactly once.")

        var frameSlots: [EdgeID] = []
        for side in 0..<6 {
            let base = side * 5
            frameSlots.append(cycle[base + 1])
            frameSlots.append(cycle[base + 2])
            frameSlots.append(cycle[base + 3])
        }

        return frameSlots.enumerated().compactMap { index, edgeID in
            index.isMultiple(of: 2) ? edgeID : nil
        }
    }

    private static func tileCoordinates() -> [(q: Int, r: Int)] {
        var coordinates: [(q: Int, r: Int)] = []

        for q in -2...2 {
            for r in -2...2 {
                let s = -q - r
                if max(abs(q), abs(r), abs(s)) <= 2 {
                    coordinates.append((q, r))
                }
            }
        }

        return coordinates.sorted { lhs, rhs in
            if lhs.r != rhs.r { return lhs.r < rhs.r }
            return lhs.q < rhs.q
        }
    }

    private static let cornerOffsets: [LatticePoint] = [
        LatticePoint(u: 1, w: 1),
        LatticePoint(u: 0, w: 2),
        LatticePoint(u: -1, w: 1),
        LatticePoint(u: -1, w: -1),
        LatticePoint(u: 0, w: -2),
        LatticePoint(u: 1, w: -1),
    ]
}

private struct LatticePoint: Hashable {
    let u: Int
    let w: Int
}

private struct EdgeKey: Hashable {
    let a: NodeID
    let b: NodeID

    init(_ first: NodeID, _ second: NodeID) {
        if first <= second {
            a = first
            b = second
        } else {
            a = second
            b = first
        }
    }
}

private struct Geometry {
    let tiles: [TileV1]
    let edges: [EdgeV1]
    let nodeCoordinates: [LatticePoint]
    let edgeToTiles: [[TileID]]
}
