import UIKit

@MainActor
enum TranscriptBubbleImageRenderer {
    static let imageSize = GameBoardSnapshotVariant.transcriptPreview.canvasSize

    static func render(
        visual: TranscriptBubbleVisual,
        assetBundle: Bundle = .main
    ) -> UIImage? {
        switch visual {
        case .none:
            nil
        case let .lobby(model):
            TranscriptLobbySnapshotRenderer.render(model: model)
        case let .board(visual):
            GameBoardSnapshotRenderer.render(
                renderModel: boardRenderModel(for: visual),
                variant: .transcriptPreview
            )
        case let .trade(visual):
            TranscriptTradeSnapshotRenderer.render(
                visual: visual,
                assetBundle: assetBundle
            )
        case let .gameOver(visual):
            TranscriptGameOverSnapshotRenderer.render(visual: visual)
        }
    }

    private static func boardRenderModel(
        for visual: TranscriptBoardVisual
    ) -> GameBoardRenderModel {
        guard !visual.showsNumberTokens else {
            return visual.renderModel
        }

        let tiles = visual.renderModel.tiles.map { tile in
            GameBoardTileRenderModel(
                tileID: tile.tileID,
                resource: tile.resource,
                number: nil,
                hasRobber: tile.hasRobber
            )
        }

        return GameBoardRenderModel(
            topology: visual.renderModel.topology,
            geometry: visual.renderModel.geometry,
            playerOrder: visual.renderModel.playerOrder,
            tiles: tiles,
            ports: visual.renderModel.ports,
            structures: visual.renderModel.structures,
            roads: visual.renderModel.roads
        )
    }
}
