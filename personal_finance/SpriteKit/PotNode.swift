//
//  PotNode.swift
//  personal_finance
//
//  Created on 2026-02-18.
//

import SpriteKit

/// Kawaii pot node with expression system and interaction animations
final class PotNode: SKNode {

    // MARK: - Expression Enum

    enum Expression {
        case expecting
        case happy
        case sleeping
        case surprised
    }

    // MARK: - Properties

    private let sceneSize: CGSize
    private let potCenterX: CGFloat
    private let potBaseY: CGFloat

    private let potWidth: CGFloat = 90
    private let potHeight: CGFloat = 60
    private let rimHeight: CGFloat = 10

    private var currentExpression: Expression = .expecting

    private var faceNodes: [SKNode] = []
    private var leftBlush: SKShapeNode?
    private var rightBlush: SKShapeNode?
    private var zzzLabel: SKLabelNode?

    /// The Y position at the top of the pot (where plants grow from)
    var potTopY: CGFloat {
        potBaseY + potHeight + rimHeight
    }

    // MARK: - Initialization

    init(sceneSize: CGSize) {
        self.sceneSize = sceneSize
        self.potCenterX = sceneSize.width / 2
        self.potBaseY = sceneSize.height * 0.18

        super.init()

        self.zPosition = 1.5

        setupPotBody()
        setupRim()
        setupSoil()
        setupBlush()
        setExpression(.expecting, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Pot Construction

    private func setupPotBody() {
        let topHalf = potWidth / 2
        let bottomHalf = potWidth * 0.35

        let cornerRadius: CGFloat = 8

        let path = CGMutablePath()

        // Build rounded trapezoid: wider top, narrower bottom
        let topLeft = CGPoint(x: potCenterX - topHalf, y: potBaseY + potHeight)
        let bottomLeft = CGPoint(x: potCenterX - bottomHalf, y: potBaseY)
        let bottomRight = CGPoint(x: potCenterX + bottomHalf, y: potBaseY)
        let topRight = CGPoint(x: potCenterX + topHalf, y: potBaseY + potHeight)

        // Start from mid-top-left, go clockwise
        path.move(to: CGPoint(x: topLeft.x + cornerRadius, y: topLeft.y))

        // Top edge
        path.addLine(to: CGPoint(x: topRight.x - cornerRadius, y: topRight.y))

        // Top-right corner
        path.addQuadCurve(
            to: CGPoint(x: topRight.x, y: topRight.y - cornerRadius),
            control: topRight
        )

        // Right edge
        path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y + cornerRadius))

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: bottomRight.x - cornerRadius, y: bottomRight.y),
            control: bottomRight
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: bottomLeft.x + cornerRadius, y: bottomLeft.y))

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: bottomLeft.x, y: bottomLeft.y + cornerRadius),
            control: bottomLeft
        )

        // Left edge
        path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y - cornerRadius))

        // Top-left corner
        path.addQuadCurve(
            to: CGPoint(x: topLeft.x + cornerRadius, y: topLeft.y),
            control: topLeft
        )

        path.closeSubpath()

        let potShape = SKShapeNode(path: path)
        potShape.fillColor = SKColor(red: 1.0, green: 0.87, blue: 0.77, alpha: 1.0)
        potShape.strokeColor = SKColor(red: 0.9, green: 0.75, blue: 0.65, alpha: 1.0)
        potShape.lineWidth = 1.5
        addChild(potShape)
    }

    private func setupRim() {
        let topHalf = potWidth / 2
        let rimWidth = topHalf + 4
        let rimY = potBaseY + potHeight
        let cornerRadius: CGFloat = 5

        let path = CGMutablePath()

        let left = CGPoint(x: potCenterX - rimWidth, y: rimY)
        let topLeft = CGPoint(x: potCenterX - rimWidth + 2, y: rimY + rimHeight)
        let topRight = CGPoint(x: potCenterX + rimWidth - 2, y: rimY + rimHeight)
        let right = CGPoint(x: potCenterX + rimWidth, y: rimY)

        path.move(to: CGPoint(x: left.x + cornerRadius, y: left.y))

        // Bottom edge (left to right)
        path.addLine(to: CGPoint(x: right.x - cornerRadius, y: right.y))

        // Right corner
        path.addQuadCurve(
            to: CGPoint(x: topRight.x, y: topRight.y - cornerRadius),
            control: CGPoint(x: right.x, y: rimY + rimHeight * 0.3)
        )

        // Top-right to top
        path.addLine(to: CGPoint(x: topRight.x, y: topRight.y))

        // Top edge
        path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y))

        // Left side up
        path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y - cornerRadius))

        // Left corner
        path.addQuadCurve(
            to: CGPoint(x: left.x + cornerRadius, y: left.y),
            control: CGPoint(x: left.x, y: rimY + rimHeight * 0.3)
        )

        path.closeSubpath()

        let rimShape = SKShapeNode(path: path)
        rimShape.fillColor = SKColor(red: 0.95, green: 0.82, blue: 0.72, alpha: 1.0)
        rimShape.strokeColor = SKColor(red: 0.9, green: 0.75, blue: 0.65, alpha: 1.0)
        rimShape.lineWidth = 1.5
        addChild(rimShape)
    }

    private func setupSoil() {
        let soilWidth = potWidth * 0.9
        let soilHeight: CGFloat = 12

        let soilShape = SKShapeNode(ellipseOf: CGSize(width: soilWidth, height: soilHeight))
        soilShape.position = CGPoint(x: potCenterX, y: potBaseY + potHeight + rimHeight - 2)
        soilShape.fillColor = SKColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
        soilShape.strokeColor = .clear
        soilShape.zPosition = 0.1
        addChild(soilShape)
    }

    private func setupBlush() {
        let eyeY = potBaseY + potHeight * 0.55
        let eyeSpacing: CGFloat = 14

        let leftBlushNode = SKShapeNode(ellipseOf: CGSize(width: 14, height: 9))
        leftBlushNode.fillColor = SKColor(red: 1.0, green: 0.6, blue: 0.65, alpha: 0.4)
        leftBlushNode.strokeColor = .clear
        leftBlushNode.position = CGPoint(x: potCenterX - eyeSpacing - 2, y: eyeY - 8)
        leftBlushNode.name = "blush_left"
        addChild(leftBlushNode)
        leftBlush = leftBlushNode

        let rightBlushNode = SKShapeNode(ellipseOf: CGSize(width: 14, height: 9))
        rightBlushNode.fillColor = SKColor(red: 1.0, green: 0.6, blue: 0.65, alpha: 0.4)
        rightBlushNode.strokeColor = .clear
        rightBlushNode.position = CGPoint(x: potCenterX + eyeSpacing + 2, y: eyeY - 8)
        rightBlushNode.name = "blush_right"
        addChild(rightBlushNode)
        rightBlush = rightBlushNode
    }

    // MARK: - Expression System

    func setExpression(_ expression: Expression, animated: Bool) {
        // Remove old face nodes
        for node in faceNodes {
            node.removeFromParent()
        }
        faceNodes.removeAll()
        zzzLabel?.removeFromParent()
        zzzLabel = nil

        currentExpression = expression

        let eyeY = potBaseY + potHeight * 0.55
        let eyeSpacing: CGFloat = 14
        let mouthY = eyeY - 14

        switch expression {
        case .expecting:
            drawExpectingFace(eyeY: eyeY, eyeSpacing: eyeSpacing, mouthY: mouthY)
        case .happy:
            drawHappyFace(eyeY: eyeY, eyeSpacing: eyeSpacing, mouthY: mouthY)
        case .sleeping:
            drawSleepingFace(eyeY: eyeY, eyeSpacing: eyeSpacing, mouthY: mouthY)
        case .surprised:
            drawSurprisedFace(eyeY: eyeY, eyeSpacing: eyeSpacing, mouthY: mouthY)
        }

        if animated {
            let scaleUp = SKAction.scale(to: 1.05, duration: 0.1)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
            run(SKAction.sequence([scaleUp, scaleDown]))
        }
    }

    private func drawExpectingFace(eyeY: CGFloat, eyeSpacing: CGFloat, mouthY: CGFloat) {
        // Round dot eyes
        let leftEye = SKShapeNode(circleOfRadius: 4)
        leftEye.fillColor = SKColor(red: 0.2, green: 0.15, blue: 0.15, alpha: 1.0)
        leftEye.strokeColor = .clear
        leftEye.position = CGPoint(x: potCenterX - eyeSpacing, y: eyeY)
        leftEye.name = "face_eye_left"
        addChild(leftEye)
        faceNodes.append(leftEye)

        let rightEye = SKShapeNode(circleOfRadius: 4)
        rightEye.fillColor = SKColor(red: 0.2, green: 0.15, blue: 0.15, alpha: 1.0)
        rightEye.strokeColor = .clear
        rightEye.position = CGPoint(x: potCenterX + eyeSpacing, y: eyeY)
        rightEye.name = "face_eye_right"
        addChild(rightEye)
        faceNodes.append(rightEye)

        // Small round mouth
        let mouth = SKShapeNode(circleOfRadius: 2.5)
        mouth.fillColor = SKColor(red: 0.85, green: 0.45, blue: 0.45, alpha: 1.0)
        mouth.strokeColor = .clear
        mouth.position = CGPoint(x: potCenterX, y: mouthY)
        mouth.name = "face_mouth"
        addChild(mouth)
        faceNodes.append(mouth)
    }

    private func drawHappyFace(eyeY: CGFloat, eyeSpacing: CGFloat, mouthY: CGFloat) {
        // Curved smile eyes (upward arcs)
        let leftEyePath = CGMutablePath()
        leftEyePath.move(to: CGPoint(x: -5, y: 0))
        leftEyePath.addQuadCurve(
            to: CGPoint(x: 5, y: 0),
            control: CGPoint(x: 0, y: 5)
        )

        let leftEye = SKShapeNode(path: leftEyePath)
        leftEye.strokeColor = SKColor(red: 0.2, green: 0.15, blue: 0.15, alpha: 1.0)
        leftEye.lineWidth = 2.5
        leftEye.lineCap = .round
        leftEye.position = CGPoint(x: potCenterX - eyeSpacing, y: eyeY)
        leftEye.name = "face_eye_left"
        addChild(leftEye)
        faceNodes.append(leftEye)

        let rightEye = SKShapeNode(path: leftEyePath)
        rightEye.strokeColor = SKColor(red: 0.2, green: 0.15, blue: 0.15, alpha: 1.0)
        rightEye.lineWidth = 2.5
        rightEye.lineCap = .round
        rightEye.position = CGPoint(x: potCenterX + eyeSpacing, y: eyeY)
        rightEye.name = "face_eye_right"
        addChild(rightEye)
        faceNodes.append(rightEye)

        // Smile arc mouth
        let mouthPath = CGMutablePath()
        mouthPath.move(to: CGPoint(x: -7, y: 0))
        mouthPath.addQuadCurve(
            to: CGPoint(x: 7, y: 0),
            control: CGPoint(x: 0, y: -6)
        )

        let mouth = SKShapeNode(path: mouthPath)
        mouth.strokeColor = SKColor(red: 0.85, green: 0.45, blue: 0.45, alpha: 1.0)
        mouth.lineWidth = 2.0
        mouth.lineCap = .round
        mouth.position = CGPoint(x: potCenterX, y: mouthY)
        mouth.name = "face_mouth"
        addChild(mouth)
        faceNodes.append(mouth)
    }

    private func drawSleepingFace(eyeY: CGFloat, eyeSpacing: CGFloat, mouthY: CGFloat) {
        // Closed eyes (horizontal lines)
        let eyeLineLength: CGFloat = 6

        let leftEyePath = CGMutablePath()
        leftEyePath.move(to: CGPoint(x: -eyeLineLength, y: 0))
        leftEyePath.addLine(to: CGPoint(x: eyeLineLength, y: 0))

        let leftEye = SKShapeNode(path: leftEyePath)
        leftEye.strokeColor = SKColor(red: 0.2, green: 0.15, blue: 0.15, alpha: 1.0)
        leftEye.lineWidth = 2.0
        leftEye.lineCap = .round
        leftEye.position = CGPoint(x: potCenterX - eyeSpacing, y: eyeY)
        leftEye.name = "face_eye_left"
        addChild(leftEye)
        faceNodes.append(leftEye)

        let rightEye = SKShapeNode(path: leftEyePath)
        rightEye.strokeColor = SKColor(red: 0.2, green: 0.15, blue: 0.15, alpha: 1.0)
        rightEye.lineWidth = 2.0
        rightEye.lineCap = .round
        rightEye.position = CGPoint(x: potCenterX + eyeSpacing, y: eyeY)
        rightEye.name = "face_eye_right"
        addChild(rightEye)
        faceNodes.append(rightEye)

        // Small line mouth
        let mouthPath = CGMutablePath()
        mouthPath.move(to: CGPoint(x: -4, y: 0))
        mouthPath.addLine(to: CGPoint(x: 4, y: 0))

        let mouth = SKShapeNode(path: mouthPath)
        mouth.strokeColor = SKColor(red: 0.85, green: 0.45, blue: 0.45, alpha: 0.6)
        mouth.lineWidth = 1.5
        mouth.lineCap = .round
        mouth.position = CGPoint(x: potCenterX, y: mouthY)
        mouth.name = "face_mouth"
        addChild(mouth)
        faceNodes.append(mouth)

        // Floating "zzZ" label
        let zzz = SKLabelNode(text: "zzZ")
        zzz.fontName = "AvenirNext-Bold"
        zzz.fontSize = 12
        zzz.fontColor = SKColor(red: 0.6, green: 0.6, blue: 0.75, alpha: 0.7)
        zzz.position = CGPoint(x: potCenterX + 25, y: eyeY + 12)
        zzz.name = "face_zzz"
        addChild(zzz)
        faceNodes.append(zzz)
        zzzLabel = zzz

        // Gentle float animation for zzZ
        let moveUp = SKAction.moveBy(x: 0, y: 5, duration: 1.2)
        let moveDown = SKAction.moveBy(x: 0, y: -5, duration: 1.2)
        let fadeIn = SKAction.fadeAlpha(to: 0.7, duration: 1.2)
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 1.2)
        let floatUp = SKAction.group([moveUp, fadeOut])
        let floatDown = SKAction.group([moveDown, fadeIn])
        let floatCycle = SKAction.sequence([floatUp, floatDown])
        zzz.run(SKAction.repeatForever(floatCycle))
    }

    private func drawSurprisedFace(eyeY: CGFloat, eyeSpacing: CGFloat, mouthY: CGFloat) {
        // Big eyes with white highlight dots
        let eyeColor = SKColor(red: 0.2, green: 0.15, blue: 0.15, alpha: 1.0)

        let leftEye = SKShapeNode(circleOfRadius: 6)
        leftEye.fillColor = eyeColor
        leftEye.strokeColor = .clear
        leftEye.position = CGPoint(x: potCenterX - eyeSpacing, y: eyeY)
        leftEye.name = "face_eye_left"
        addChild(leftEye)
        faceNodes.append(leftEye)

        let leftHighlight = SKShapeNode(circleOfRadius: 2)
        leftHighlight.fillColor = .white
        leftHighlight.strokeColor = .clear
        leftHighlight.position = CGPoint(x: 2, y: 2)
        leftEye.addChild(leftHighlight)

        let rightEye = SKShapeNode(circleOfRadius: 6)
        rightEye.fillColor = eyeColor
        rightEye.strokeColor = .clear
        rightEye.position = CGPoint(x: potCenterX + eyeSpacing, y: eyeY)
        rightEye.name = "face_eye_right"
        addChild(rightEye)
        faceNodes.append(rightEye)

        let rightHighlight = SKShapeNode(circleOfRadius: 2)
        rightHighlight.fillColor = .white
        rightHighlight.strokeColor = .clear
        rightHighlight.position = CGPoint(x: 2, y: 2)
        rightEye.addChild(rightHighlight)

        // O-shaped ellipse mouth
        let mouth = SKShapeNode(ellipseOf: CGSize(width: 8, height: 10))
        mouth.fillColor = SKColor(red: 0.85, green: 0.45, blue: 0.45, alpha: 1.0)
        mouth.strokeColor = SKColor(red: 0.7, green: 0.35, blue: 0.35, alpha: 1.0)
        mouth.lineWidth = 1.0
        mouth.position = CGPoint(x: potCenterX, y: mouthY)
        mouth.name = "face_mouth"
        addChild(mouth)
        faceNodes.append(mouth)
    }

    // MARK: - Interaction Animations

    /// Momentarily close eyes (0.15s) then revert — only from .expecting state
    func playBlink() {
        guard currentExpression == .expecting else { return }

        setExpression(.sleeping, animated: false)
        // Remove zzZ for blink (not actually sleeping)
        zzzLabel?.removeFromParent()
        zzzLabel = nil

        let wait = SKAction.wait(forDuration: 0.15)
        run(wait) { [weak self] in
            self?.setExpression(.expecting, animated: false)
        }
    }

    /// Wobble left/right rotation + expression -> happy, revert after 1.5s
    func playTapReaction() {
        setExpression(.happy, animated: true)

        let rotateLeft = SKAction.rotate(toAngle: -CGFloat.pi / 30, duration: 0.08)
        let rotateRight = SKAction.rotate(toAngle: CGFloat.pi / 30, duration: 0.08)
        let rotateCenter = SKAction.rotate(toAngle: 0, duration: 0.08)
        let wobble = SKAction.sequence([rotateLeft, rotateRight, rotateLeft, rotateRight, rotateCenter])
        run(wobble)

        let revert = SKAction.wait(forDuration: 1.5)
        run(revert) { [weak self] in
            self?.setExpression(.expecting, animated: true)
        }
    }

    /// Deepen blush (alpha 0.4 -> 0.7) + happy expression, revert after 2s
    func playLongPressReaction() {
        setExpression(.happy, animated: true)

        // Deepen blush
        let deepenBlush = SKAction.fadeAlpha(to: 0.7, duration: 0.3)
        leftBlush?.run(deepenBlush)
        rightBlush?.run(deepenBlush)

        let revert = SKAction.wait(forDuration: 2.0)
        run(revert) { [weak self] in
            guard let self = self else { return }
            self.setExpression(.expecting, animated: true)

            // Restore blush
            let restoreBlush = SKAction.fadeAlpha(to: 0.4, duration: 0.3)
            self.leftBlush?.run(restoreBlush)
            self.rightBlush?.run(restoreBlush)
        }
    }

    /// Jump up 15pt and back down + surprised -> happy -> expecting sequence
    func playJumpReaction() {
        setExpression(.surprised, animated: true)

        let jumpUp = SKAction.moveBy(x: 0, y: 15, duration: 0.15)
        jumpUp.timingMode = .easeOut
        let jumpDown = SKAction.moveBy(x: 0, y: -15, duration: 0.2)
        jumpDown.timingMode = .easeIn
        let jumpSequence = SKAction.sequence([jumpUp, jumpDown])
        run(jumpSequence)

        // Expression sequence: surprised -> happy -> expecting
        let waitForHappy = SKAction.wait(forDuration: 0.5)
        run(waitForHappy) { [weak self] in
            self?.setExpression(.happy, animated: true)

            let waitForExpecting = SKAction.wait(forDuration: 1.0)
            self?.run(waitForExpecting) { [weak self] in
                self?.setExpression(.expecting, animated: true)
            }
        }
    }
}
