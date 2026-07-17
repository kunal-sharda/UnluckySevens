import SceneKit
import UIKit

final class GameDiceBowlSceneController: NSObject {
    private let scene = SCNScene()
    private let firstDie = SCNNode()
    private let secondDie = SCNNode()
    private weak var renderView: SCNView?
    private var result = GameDiceRollResult(first: 1, second: 1)
    private var onAnimationFinished: (() -> Void)?
    private var isActive = false
    private var hasSettled = false

    func makeView(
        result: GameDiceRollResult,
        onAnimationFinished: @escaping () -> Void
    ) -> SCNView {
        self.result = result
        self.onAnimationFinished = onAnimationFinished

        let view = SCNView()
        view.scene = scene
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling2X
        view.preferredFramesPerSecond = 60
        view.rendersContinuously = false
        view.isPlaying = false
        view.autoenablesDefaultLighting = false
        renderView = view

        configureScene()
        prepareDice()
        return view
    }

    func setActive(
        _ active: Bool,
        result: GameDiceRollResult,
        onAnimationFinished: @escaping () -> Void
    ) {
        guard active != isActive else { return }
        isActive = active

        if active {
            self.result = result
            self.onAnimationFinished = onAnimationFinished
            hasSettled = false
            resetDiceForRoll()
            renderView?.rendersContinuously = true
            renderView?.isPlaying = true
            startAuthoredRoll()
        } else {
            stopActions()
            hasSettled = false
            resetDiceForRoll()
            renderView?.rendersContinuously = false
            renderView?.isPlaying = false
        }
    }

    func settle(result: GameDiceRollResult) {
        guard !hasSettled else { return }
        hasSettled = true
        stopActions()
        placeSettledDice(result: result)
        renderView?.rendersContinuously = false
        renderView?.isPlaying = false
    }

    private func configureScene() {
        scene.background.contents = UIColor.clear

        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 5.7
        camera.zNear = 0.1
        camera.zFar = 100
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 9.6, 7.8)
        cameraNode.look(at: SCNVector3(0, 0.18, 0))
        scene.rootNode.addChildNode(cameraNode)

        let key = SCNLight()
        key.type = .directional
        key.intensity = 860
        key.color = UIColor(red: 1.0, green: 0.94, blue: 0.82, alpha: 1)
        key.castsShadow = true
        key.shadowRadius = 5
        key.shadowColor = UIColor.black.withAlphaComponent(0.30)
        let keyNode = SCNNode()
        keyNode.light = key
        keyNode.eulerAngles = SCNVector3(-0.78, -0.48, 0)
        scene.rootNode.addChildNode(keyNode)

        let fill = SCNLight()
        fill.type = .omni
        fill.intensity = 260
        fill.color = UIColor(red: 1.0, green: 0.88, blue: 0.68, alpha: 1)
        let fillNode = SCNNode()
        fillNode.light = fill
        fillNode.position = SCNVector3(4.5, 5.5, 3)
        scene.rootNode.addChildNode(fillNode)

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 520
        ambient.color = UIColor(red: 0.82, green: 0.77, blue: 0.66, alpha: 1)
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        scene.rootNode.addChildNode(makeBowl())
    }

    private func makeBowl() -> SCNNode {
        let bowl = SCNNode()

        let outlineBase = SCNCylinder(radius: 4.02, height: 0.34)
        outlineBase.radialSegmentCount = 40
        outlineBase.firstMaterial = material(red: 0.12, green: 0.085, blue: 0.055, roughness: 0.86)
        let outlineBaseNode = SCNNode(geometry: outlineBase)
        outlineBaseNode.position.y = 0.01
        bowl.addChildNode(outlineBaseNode)

        let base = SCNCylinder(radius: 3.92, height: 0.30)
        base.radialSegmentCount = 40
        base.firstMaterial = material(red: 0.44, green: 0.26, blue: 0.12, roughness: 0.82)
        let baseNode = SCNNode(geometry: base)
        baseNode.position.y = 0.05
        bowl.addChildNode(baseNode)

        let well = SCNCylinder(radius: 3.42, height: 0.32)
        well.radialSegmentCount = 40
        well.firstMaterial = material(red: 0.13, green: 0.20, blue: 0.16, roughness: 1.0)
        let wellNode = SCNNode(geometry: well)
        wellNode.position.y = 0.11
        bowl.addChildNode(wellNode)

        let rimOutline = SCNTorus(ringRadius: 3.62, pipeRadius: 0.34)
        rimOutline.ringSegmentCount = 40
        rimOutline.pipeSegmentCount = 10
        rimOutline.firstMaterial = material(red: 0.12, green: 0.085, blue: 0.055, roughness: 0.86)
        let rimOutlineNode = SCNNode(geometry: rimOutline)
        rimOutlineNode.position.y = 0.33
        bowl.addChildNode(rimOutlineNode)

        let rim = SCNTorus(ringRadius: 3.62, pipeRadius: 0.255)
        rim.ringSegmentCount = 40
        rim.pipeSegmentCount = 10
        rim.firstMaterial = material(red: 0.49, green: 0.29, blue: 0.13, roughness: 0.78)
        let rimNode = SCNNode(geometry: rim)
        rimNode.position.y = 0.35
        bowl.addChildNode(rimNode)

        return bowl
    }

    private func prepareDice() {
        configureDie(firstDie)
        configureDie(secondDie)
        scene.rootNode.addChildNode(firstDie)
        scene.rootNode.addChildNode(secondDie)
        resetDiceForRoll()
    }

    private func configureDie(_ node: SCNNode) {
        let box = SCNBox(width: 1.18, height: 1.18, length: 1.18, chamferRadius: 0.15)
        box.chamferSegmentCount = 4
        box.materials = [2, 4, 5, 3, 1, 6].map(faceMaterial)
        node.geometry = box
        node.castsShadow = true
    }

    private func resetDiceForRoll() {
        firstDie.position = SCNVector3(-2.35, 3.55, 0.82)
        firstDie.eulerAngles = SCNVector3(0.74, -0.52, 1.08)
        secondDie.position = SCNVector3(2.35, 3.78, -0.72)
        secondDie.eulerAngles = SCNVector3(-0.62, 0.91, -0.84)
        applyStandardFaces(to: firstDie)
        applyStandardFaces(to: secondDie)
    }

    private func startAuthoredRoll() {
        setTopFace(result.first, on: firstDie)
        setTopFace(result.second, on: secondDie)

        firstDie.runAction(
            rollAction(
                delay: 0,
                start: SCNVector3(-2.35, 3.55, 0.82),
                firstImpact: SCNVector3(0.42, 0.78, -0.72),
                secondImpact: SCNVector3(-0.54, 0.76, 0.58),
                finalPosition: SCNVector3(-1.05, 0.88, 0.15),
                finalAngles: SCNVector3(0.03, -0.20, -0.05),
                firstArcHeight: 1.18,
                secondArcHeight: 0.56,
                durations: (0.36, 0.66, 0.52, 0.34),
                spins: [SCNVector3(5.8, 7.4, 4.1), SCNVector3(4.4, 5.1, -3.2), SCNVector3(2.7, 3.2, 1.8)]
            )
        )

        secondDie.runAction(
            rollAction(
                delay: 0.06,
                start: SCNVector3(2.35, 3.78, -0.72),
                firstImpact: SCNVector3(-0.34, 0.80, 0.72),
                secondImpact: SCNVector3(0.66, 0.78, -0.58),
                finalPosition: SCNVector3(1.05, 0.88, -0.12),
                finalAngles: SCNVector3(-0.04, 0.24, 0.07),
                firstArcHeight: 1.34,
                secondArcHeight: 0.68,
                durations: (0.40, 0.70, 0.58, 0.40),
                spins: [SCNVector3(-6.4, -7.0, 4.8), SCNVector3(-4.1, 5.6, 3.5), SCNVector3(-2.4, -3.6, 2.2)]
            )
        ) { [weak self] in
            guard let self else { return }
            self.hasSettled = true
            self.renderView?.rendersContinuously = false
            self.renderView?.isPlaying = false
            self.onAnimationFinished?()
        }
    }

    private func rollAction(
        delay: TimeInterval,
        start: SCNVector3,
        firstImpact: SCNVector3,
        secondImpact: SCNVector3,
        finalPosition: SCNVector3,
        finalAngles: SCNVector3,
        firstArcHeight: Float,
        secondArcHeight: Float,
        durations: (fall: TimeInterval, firstArc: TimeInterval, secondArc: TimeInterval, settle: TimeInterval),
        spins: [SCNVector3]
    ) -> SCNAction {
        .sequence([
            .wait(duration: delay),
            trajectory(
                from: start,
                to: firstImpact,
                arcHeight: 0,
                duration: durations.fall,
                spin: spins[0]
            ),
            trajectory(
                from: firstImpact,
                to: secondImpact,
                arcHeight: firstArcHeight,
                duration: durations.firstArc,
                spin: spins[1]
            ),
            trajectory(
                from: secondImpact,
                to: finalPosition,
                arcHeight: secondArcHeight,
                duration: durations.secondArc,
                spin: spins[2]
            ),
            settleMovement(
                to: finalPosition,
                angles: finalAngles,
                duration: durations.settle
            ),
        ])
    }

    private func trajectory(
        from start: SCNVector3,
        to end: SCNVector3,
        arcHeight: Float,
        duration: TimeInterval,
        spin: SCNVector3
    ) -> SCNAction {
        let move = SCNAction.customAction(duration: duration) { node, elapsed in
            let progress = min(1, Float(elapsed) / Float(duration))
            let inverse = 1 - progress
            node.position = SCNVector3(
                start.x * inverse + end.x * progress,
                start.y * inverse + end.y * progress
                    + 4 * arcHeight * progress * inverse,
                start.z * inverse + end.z * progress
            )
        }
        let rotate = SCNAction.rotateBy(
            x: CGFloat(spin.x), y: CGFloat(spin.y), z: CGFloat(spin.z), duration: duration
        )
        rotate.timingMode = .easeOut
        return .group([move, rotate])
    }

    private func settleMovement(
        to position: SCNVector3,
        angles: SCNVector3,
        duration: TimeInterval
    ) -> SCNAction {
        let move = SCNAction.move(to: position, duration: duration)
        move.timingMode = .easeOut
        let orient = SCNAction.rotateTo(
            x: CGFloat(angles.x),
            y: CGFloat(angles.y),
            z: CGFloat(angles.z),
            duration: duration,
            usesShortestUnitArc: true
        )
        orient.timingMode = .easeOut
        return .group([move, orient])
    }

    private func stopActions() {
        firstDie.removeAllActions()
        secondDie.removeAllActions()
    }

    private func placeSettledDice(result: GameDiceRollResult) {
        setTopFace(result.first, on: firstDie)
        setTopFace(result.second, on: secondDie)
        firstDie.position = SCNVector3(-1.05, 0.88, 0.15)
        secondDie.position = SCNVector3(1.05, 0.88, -0.12)
        firstDie.eulerAngles = SCNVector3(0.03, -0.20, -0.05)
        secondDie.eulerAngles = SCNVector3(-0.04, 0.24, 0.07)
    }

    private func applyStandardFaces(to node: SCNNode) {
        node.geometry?.materials = [2, 4, 5, 3, 1, 6].map(faceMaterial)
    }

    private func setTopFace(_ value: Int, on node: SCNNode) {
        let bounded = min(max(value, 1), 6)
        let sideA = bounded == 6 ? 1 : bounded + 1
        let sideB = bounded <= 2 ? bounded + 3 : bounded - 2
        node.geometry?.materials = [sideA, sideB, 7 - sideA, 7 - sideB, bounded, 7 - bounded]
            .map(faceMaterial)
    }

    private func faceMaterial(_ value: Int) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = Self.faceTexture(value: value)
        material.roughness.contents = 0.78
        material.metalness.contents = 0
        material.lightingModel = .physicallyBased
        material.isDoubleSided = false
        return material
    }

    private func material(red: CGFloat, green: CGFloat, blue: CGFloat, roughness: CGFloat) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: red, green: green, blue: blue, alpha: 1)
        material.roughness.contents = roughness
        material.metalness.contents = 0
        material.lightingModel = .physicallyBased
        return material
    }

    private static let textureCache = NSCache<NSNumber, UIImage>()

    private static func faceTexture(value: Int) -> UIImage {
        let key = NSNumber(value: value)
        if let cached = textureCache.object(forKey: key) { return cached }

        let size = CGSize(width: 192, height: 192)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.96, green: 0.91, blue: 0.80, alpha: 1).setFill()
            context.fill(rect)

            UIColor(red: 0.12, green: 0.085, blue: 0.055, alpha: 1).setFill()
            let radius: CGFloat = 13
            for point in pipPositions(for: value) {
                let center = CGPoint(x: point.x * size.width, y: point.y * size.height)
                context.cgContext.fillEllipse(in: CGRect(
                    x: center.x - radius, y: center.y - radius,
                    width: radius * 2, height: radius * 2
                ))
            }
        }
        textureCache.setObject(image, forKey: key)
        return image
    }

    private static func pipPositions(for value: Int) -> [CGPoint] {
        let low: CGFloat = 0.27
        let mid: CGFloat = 0.50
        let high: CGFloat = 0.73
        switch min(max(value, 1), 6) {
        case 1: return [CGPoint(x: mid, y: mid)]
        case 2: return [CGPoint(x: low, y: low), CGPoint(x: high, y: high)]
        case 3: return [CGPoint(x: low, y: low), CGPoint(x: mid, y: mid), CGPoint(x: high, y: high)]
        case 4: return [CGPoint(x: low, y: low), CGPoint(x: high, y: low), CGPoint(x: low, y: high), CGPoint(x: high, y: high)]
        case 5: return [CGPoint(x: low, y: low), CGPoint(x: high, y: low), CGPoint(x: mid, y: mid), CGPoint(x: low, y: high), CGPoint(x: high, y: high)]
        default: return [CGPoint(x: low, y: low), CGPoint(x: high, y: low), CGPoint(x: low, y: mid), CGPoint(x: high, y: mid), CGPoint(x: low, y: high), CGPoint(x: high, y: high)]
        }
    }
}
