@testable import MessagesExtensionSupport
import ULS_CoreGame
import XCTest
import CoreImage
import UIKit

@MainActor
final class GameBoardSnapshotRendererTests: XCTestCase {
    func testSnapshotRendererProducesBubbleSizedImage() throws {
        let renderModel = try XCTUnwrap(makeRenderModel())

        let image = try XCTUnwrap(
            GameBoardSnapshotRenderer.render(
            renderModel: renderModel,
            variant: .bubbleCompact
            )
        )

        XCTAssertEqual(image.size.width, GameBoardSnapshotVariant.bubbleCompact.canvasSize.width, accuracy: 0.5)
        XCTAssertEqual(image.size.height, GameBoardSnapshotVariant.bubbleCompact.canvasSize.height, accuracy: 0.5)
    }

    func testSnapshotRendererProducesTranscriptPreviewImage() throws {
        let renderModel = try XCTUnwrap(makeRenderModel())

        let image = try XCTUnwrap(
            GameBoardSnapshotRenderer.render(
            renderModel: renderModel,
            variant: .transcriptPreview
            )
        )

        XCTAssertEqual(image.size.width, GameBoardSnapshotVariant.transcriptPreview.canvasSize.width, accuracy: 0.5)
        XCTAssertEqual(image.size.height, GameBoardSnapshotVariant.transcriptPreview.canvasSize.height, accuracy: 0.5)

        let attachment = XCTAttachment(image: image)
        attachment.name = "Approved robber on transcript board snapshot"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testFourPlayerBoardVisualMatrix() throws {
        let model = try XCTUnwrap(makeRenderModel())
        XCTAssertEqual(Set(model.roads.map(\.owner)).count, 4)
        let empty = GameBoardRenderModel(topology: model.topology, geometry: model.geometry,
            playerOrder: model.playerOrder, tiles: model.tiles, ports: model.ports, structures: [], roads: [])
        // Machado et al. full-severity matrices, reproduced in Colour's BSD-licensed
        // blindness/datasets/machado2010.py. Simulations are diagnostic, not human acceptance.
        let transforms: [(String, [[CGFloat]])] = [
            ("protan", [[0.152286,1.052583,-0.204868],[0.114503,0.786281,0.099216],[-0.003882,-0.048116,1.051998]]),
            ("deutan", [[0.367322,0.860646,-0.227968],[0.280085,0.672501,0.047413],[-0.011820,0.042940,0.968881]]),
            ("tritan", [[1.255528,-0.076749,-0.178779],[-0.078411,0.930809,0.147602],[0.004733,0.691367,0.303900]]),
            ("grayscale", Array(repeating: [0.2126,0.7152,0.0722], count: 3))
        ]
        let context = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!])
        for variant in [GameBoardSnapshotVariant.bubbleCompact, .transcriptPreview] {
            let image = try XCTUnwrap(GameBoardSnapshotRenderer.render(renderModel: model, variant: variant))
            let emptyImage = try XCTUnwrap(GameBoardSnapshotRenderer.render(renderModel: empty, variant: variant))
            XCTAssertNotEqual(image.pngData(), emptyImage.pngData(), "Ownership pieces must reach the production renderer")
            let normal = XCTAttachment(image: image)
            normal.name = "Four owners normal \(variant)"; normal.lifetime = .keepAlways; add(normal)
            let input = try XCTUnwrap(CIImage(image: image))
            for (name, matrix) in transforms {
                let filter = try XCTUnwrap(CIFilter(name: "CIColorMatrix"))
                filter.setValue(input, forKey: kCIInputImageKey)
                for (index, key) in ["inputRVector", "inputGVector", "inputBVector"].enumerated() {
                    let row = matrix[index]
                    filter.setValue(CIVector(x: row[0], y: row[1], z: row[2], w: 0), forKey: key)
                }
                let output = try XCTUnwrap(filter.outputImage)
                let cg = try XCTUnwrap(context.createCGImage(output, from: input.extent))
                let capture = XCTAttachment(image: UIImage(cgImage: cg))
                capture.name = "Four owners \(name) \(variant)"; capture.lifetime = .keepAlways; add(capture)
            }
        }
    }

    private func makeRenderModel() -> GameBoardRenderModel? {
        let board = BoardSetupV1(
            resourcesByTile: [
                .wood, .brick, .desert, .sheep, .wheat,
                .ore, .wood, .brick, .sheep, .wheat,
                .ore, .wood, .brick, .sheep, .wheat,
                .ore, .wood, .brick, .sheep,
            ],
            numbersByTile: [
                5, 2, nil, 6, 3,
                8, 10, 9, 12, 11,
                4, 8, 10, 9, 4,
                5, 6, 3, 11,
            ],
            portsByIndex: StandardBoardTopologyV1.standard().ports.map(\.kind),
            robberTile: 2,
            generator: .noRedAdjacentV1,
            boardHash: ""
        ).rehashed()

        let state = CoreGameStateV1(
            gameId: "snapshot-renderer",
            rev: 9,
            prevHash: "hash-8",
            stateHash: "",
            roster: ["A", "B", "C", "D"],
            currentPlayer: "A",
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: ["A": .zero, "B": .zero, "C": .zero],
            settlementsByNode: [0: "A", 20: "C"],
            citiesByNode: [9: "B", 30: "D"],
            roadsByEdge: [3: "A", 15: "B", 30: "C", 45: "D"],
            boardRules: BoardRulesV1(strategy: .noRedAdjacentV1),
            board: board,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 2))
        ).rehashed()

        return GameBoardRenderModelBuilder.build(state: state)
    }
}
