import CoreGraphics

enum GameDiePipLayout {
    static func positions(for value: Int) -> [CGPoint] {
        let topLeft = CGPoint(x: 0.28, y: 0.28)
        let topRight = CGPoint(x: 0.72, y: 0.28)
        let middleLeft = CGPoint(x: 0.28, y: 0.50)
        let center = CGPoint(x: 0.50, y: 0.50)
        let middleRight = CGPoint(x: 0.72, y: 0.50)
        let bottomLeft = CGPoint(x: 0.28, y: 0.72)
        let bottomRight = CGPoint(x: 0.72, y: 0.72)

        switch value {
        case 1: return [center]
        case 2: return [topLeft, bottomRight]
        case 3: return [topLeft, center, bottomRight]
        case 4: return [topLeft, topRight, bottomLeft, bottomRight]
        case 5: return [topLeft, topRight, center, bottomLeft, bottomRight]
        case 6: return [topLeft, topRight, middleLeft, middleRight, bottomLeft, bottomRight]
        default: return []
        }
    }
}
