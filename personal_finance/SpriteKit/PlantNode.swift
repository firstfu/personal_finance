//
//  PlantNode.swift
//  personal_finance
//
//  Created on 2026-02-18.
//

import SpriteKit

/// Core plant node that draws a sprout using bezier curves and supports morphing between 5 growth stages
final class PlantNode: SKNode {

    // MARK: - Properties

    private let baseY: CGFloat
    private let centerX: CGFloat

    private var seedNode: SKShapeNode?
    private var stemNode: SKShapeNode?
    private var leaves: [SKShapeNode] = []
    private var flowerNode: SKNode?
    private var currentStage: Int = -1

    // MARK: - Initialization

    init(sceneSize: CGSize) {
        // ground + pot + soil offset
        self.baseY = sceneSize.height * 0.22 + 55 + 4
        self.centerX = sceneSize.width / 2

        super.init()

        self.zPosition = 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API

    /// Morph to a specific growth stage
    func morphTo(stage: Int, animated: Bool) {
        if animated && currentStage >= 0 {
            // Fade out old children
            let fadeOut = SKAction.fadeOut(withDuration: 0.4)
            for child in children {
                child.run(fadeOut)
            }

            // Build new stage after fade out
            let wait = SKAction.wait(forDuration: 0.3)
            run(wait) { [weak self] in
                guard let self = self else { return }
                self.removeAllChildren()
                self.buildStage(stage)
                self.currentStage = stage

                // Fade in new children
                for child in self.children {
                    child.alpha = 0
                    child.run(SKAction.fadeIn(withDuration: 0.4))
                }

                // Restart idle after total 0.8s
                let finalWait = SKAction.wait(forDuration: 0.8)
                self.run(finalWait) {
                    self.startIdleAnimation()
                }
            }
        } else {
            removeAllChildren()
            buildStage(stage)
            currentStage = stage
            startIdleAnimation()
        }
    }

    /// Play growth spurt animation
    func playGrowthSpurt() {
        // Stem moves up 3pt then back 1.5pt
        if let stem = stemNode {
            let moveUp = SKAction.moveBy(x: 0, y: 3, duration: 0.6)
            let moveDown = SKAction.moveBy(x: 0, y: -1.5, duration: 0.3)
            stem.run(SKAction.sequence([moveUp, moveDown]))
        }

        // Leaves scale to 1.1 then back to 1.0
        for leaf in leaves {
            let scaleUp = SKAction.scale(to: 1.1, duration: 0.6)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.3)
            leaf.run(SKAction.sequence([scaleUp, scaleDown]))
        }
    }

    /// Start idle animation based on current stage
    func startIdleAnimation() {
        // Stop all existing actions
        removeAllActions()
        for child in children {
            child.removeAllActions()
        }

        switch currentStage {
        case 0:
            // Seed breathes
            if let seed = seedNode {
                let scaleDown = SKAction.scale(to: 0.97, duration: 1.5)
                let scaleUp = SKAction.scale(to: 1.03, duration: 1.5)
                let breathe = SKAction.sequence([scaleDown, scaleUp])
                seed.run(SKAction.repeatForever(breathe))
            }

        case 1...3:
            // Leaves sway with staggered timing
            for (index, leaf) in leaves.enumerated() {
                let delay = Double(index) * 0.15
                let rotateLeft = SKAction.rotate(toAngle: -CGFloat.pi / 36, duration: 2.0)
                let rotateRight = SKAction.rotate(toAngle: CGFloat.pi / 36, duration: 2.0)
                let sway = SKAction.sequence([rotateLeft, rotateRight])
                let swayForever = SKAction.repeatForever(sway)
                let delayed = SKAction.sequence([SKAction.wait(forDuration: delay), swayForever])
                leaf.run(delayed)
            }

        case 4:
            // Leaves sway
            for (index, leaf) in leaves.enumerated() {
                let delay = Double(index) * 0.15
                let rotateLeft = SKAction.rotate(toAngle: -CGFloat.pi / 36, duration: 2.0)
                let rotateRight = SKAction.rotate(toAngle: CGFloat.pi / 36, duration: 2.0)
                let sway = SKAction.sequence([rotateLeft, rotateRight])
                let swayForever = SKAction.repeatForever(sway)
                let delayed = SKAction.sequence([SKAction.wait(forDuration: delay), swayForever])
                leaf.run(delayed)
            }

            // Flower gently rotates
            if let flower = flowerNode {
                let rotateRight = SKAction.rotate(byAngle: CGFloat.pi / 60, duration: 3.0)
                let rotateLeft = SKAction.rotate(byAngle: -CGFloat.pi / 60, duration: 3.0)
                let rotate = SKAction.sequence([rotateRight, rotateLeft])
                flower.run(SKAction.repeatForever(rotate))
            }

        default:
            break
        }
    }

    // MARK: - Stage Building

    private func buildStage(_ stage: Int) {
        seedNode = nil
        stemNode = nil
        leaves = []
        flowerNode = nil

        switch stage {
        case 0:
            buildSeed()
        case 1:
            buildSprout()
        case 2:
            buildSeedling()
        case 3:
            buildBushy()
        case 4:
            buildFlowering()
        default:
            break
        }
    }

    private func buildSeed() {
        // Brown ellipse with small crack line
        let seedShape = SKShapeNode(ellipseOf: CGSize(width: 24, height: 18))
        seedShape.fillColor = SKColor(red: 0.55, green: 0.38, blue: 0.18, alpha: 1.0)
        seedShape.strokeColor = SKColor(red: 0.45, green: 0.30, blue: 0.15, alpha: 1.0)
        seedShape.lineWidth = 1.5
        seedShape.position = CGPoint(x: centerX, y: baseY + 8)

        // Add small crack line
        let crackPath = CGMutablePath()
        crackPath.move(to: CGPoint(x: -2, y: 0))
        crackPath.addLine(to: CGPoint(x: 2, y: 4))
        let crack = SKShapeNode(path: crackPath)
        crack.strokeColor = SKColor(red: 0.45, green: 0.30, blue: 0.15, alpha: 1.0)
        crack.lineWidth = 1.0
        seedShape.addChild(crack)

        addChild(seedShape)
        seedNode = seedShape
    }

    private func buildSprout() {
        // Stem
        let stemPath = createStemPath(height: 50, curve: 8, width: 3)
        let stem = SKShapeNode(path: stemPath)
        stem.strokeColor = SKColor(red: 0.45, green: 0.72, blue: 0.22, alpha: 1.0)
        stem.lineWidth = 3
        stem.lineCap = .round
        addChild(stem)
        stemNode = stem

        // 2 small cotyledon leaves
        let leafColor = SKColor(red: 0.55, green: 0.78, blue: 0.25, alpha: 1.0)

        let leaf1 = createLeaf(
            at: CGPoint(x: centerX - 4, y: baseY + 30),
            size: CGSize(width: 18, height: 10),
            angle: -CGFloat.pi / 6,
            color: leafColor
        )
        addChild(leaf1)
        leaves.append(leaf1)

        let leaf2 = createLeaf(
            at: CGPoint(x: centerX + 4, y: baseY + 32),
            size: CGSize(width: 18, height: 10),
            angle: CGFloat.pi / 6,
            color: leafColor
        )
        addChild(leaf2)
        leaves.append(leaf2)
    }

    private func buildSeedling() {
        // Stem
        let stemPath = createStemPath(height: 90, curve: 12, width: 4)
        let stem = SKShapeNode(path: stemPath)
        stem.strokeColor = SKColor(red: 0.40, green: 0.68, blue: 0.20, alpha: 1.0)
        stem.lineWidth = 4
        stem.lineCap = .round
        addChild(stem)
        stemNode = stem

        // 3 leaves at varying heights
        let leafColor = SKColor(red: 0.50, green: 0.76, blue: 0.22, alpha: 1.0)

        let leaf1 = createLeaf(
            at: CGPoint(x: centerX - 6, y: baseY + 40),
            size: CGSize(width: 22, height: 12),
            angle: -CGFloat.pi / 5,
            color: leafColor
        )
        addChild(leaf1)
        leaves.append(leaf1)

        let leaf2 = createLeaf(
            at: CGPoint(x: centerX + 8, y: baseY + 55),
            size: CGSize(width: 24, height: 13),
            angle: CGFloat.pi / 4.5,
            color: leafColor
        )
        addChild(leaf2)
        leaves.append(leaf2)

        let leaf3 = createLeaf(
            at: CGPoint(x: centerX - 5, y: baseY + 70),
            size: CGSize(width: 20, height: 11),
            angle: -CGFloat.pi / 6,
            color: leafColor
        )
        addChild(leaf3)
        leaves.append(leaf3)
    }

    private func buildBushy() {
        // Stem
        let stemPath = createStemPath(height: 130, curve: 15, width: 5.5)
        let stem = SKShapeNode(path: stemPath)
        stem.strokeColor = SKColor(red: 0.30, green: 0.55, blue: 0.15, alpha: 1.0)
        stem.lineWidth = 5.5
        stem.lineCap = .round
        addChild(stem)
        stemNode = stem

        // 2 small branches
        let branch1 = createBranch(
            from: CGPoint(x: centerX + 2, y: baseY + 70),
            length: 20,
            angle: CGFloat.pi / 4
        )
        addChild(branch1)

        let branch2 = createBranch(
            from: CGPoint(x: centerX + 5, y: baseY + 100),
            length: 18,
            angle: -CGFloat.pi / 5
        )
        addChild(branch2)

        // 6 leaves
        let leafColor = SKColor(red: 0.35, green: 0.65, blue: 0.18, alpha: 1.0)

        let leaf1 = createLeaf(
            at: CGPoint(x: centerX - 8, y: baseY + 50),
            size: CGSize(width: 26, height: 14),
            angle: -CGFloat.pi / 4,
            color: leafColor
        )
        addChild(leaf1)
        leaves.append(leaf1)

        let leaf2 = createLeaf(
            at: CGPoint(x: centerX + 10, y: baseY + 65),
            size: CGSize(width: 28, height: 15),
            angle: CGFloat.pi / 3.5,
            color: leafColor
        )
        addChild(leaf2)
        leaves.append(leaf2)

        let leaf3 = createLeaf(
            at: CGPoint(x: centerX - 6, y: baseY + 80),
            size: CGSize(width: 24, height: 13),
            angle: -CGFloat.pi / 6,
            color: leafColor
        )
        addChild(leaf3)
        leaves.append(leaf3)

        let leaf4 = createLeaf(
            at: CGPoint(x: centerX + 12, y: baseY + 95),
            size: CGSize(width: 27, height: 14),
            angle: CGFloat.pi / 4,
            color: leafColor
        )
        addChild(leaf4)
        leaves.append(leaf4)

        let leaf5 = createLeaf(
            at: CGPoint(x: centerX - 7, y: baseY + 110),
            size: CGSize(width: 25, height: 13),
            angle: -CGFloat.pi / 5,
            color: leafColor
        )
        addChild(leaf5)
        leaves.append(leaf5)

        let leaf6 = createLeaf(
            at: CGPoint(x: centerX + 8, y: baseY + 120),
            size: CGSize(width: 23, height: 12),
            angle: CGFloat.pi / 6,
            color: leafColor
        )
        addChild(leaf6)
        leaves.append(leaf6)
    }

    private func buildFlowering() {
        // Build bushy stage first
        buildBushy()

        // Add flower on top
        let flower = SKNode()
        flower.position = CGPoint(x: centerX + 15 * 0.3, y: baseY + 130)

        // 5 pink oval petals arranged in circle
        let petalColor = SKColor(red: 1.0, green: 0.75, blue: 0.85, alpha: 1.0)
        let petalCount = 5
        let angleStep = (2 * CGFloat.pi) / CGFloat(petalCount)

        for i in 0..<petalCount {
            let angle = angleStep * CGFloat(i) - CGFloat.pi / 2
            let petalX = cos(angle) * 10
            let petalY = sin(angle) * 10

            let petal = SKShapeNode(ellipseOf: CGSize(width: 12, height: 20))
            petal.fillColor = petalColor
            petal.strokeColor = SKColor(red: 0.9, green: 0.65, blue: 0.75, alpha: 1.0)
            petal.lineWidth = 1.0
            petal.position = CGPoint(x: petalX, y: petalY)
            petal.zRotation = angle
            flower.addChild(petal)
        }

        // Yellow center
        let center = SKShapeNode(circleOfRadius: 7)
        center.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.30, alpha: 1.0)
        center.strokeColor = SKColor(red: 0.9, green: 0.75, blue: 0.25, alpha: 1.0)
        center.lineWidth = 1.0
        center.zPosition = 1
        flower.addChild(center)

        // Glow circle
        let glow = SKShapeNode(circleOfRadius: 25)
        glow.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.90, alpha: 0.25)
        glow.strokeColor = .clear
        glow.zPosition = -1
        flower.addChild(glow)

        addChild(flower)
        flowerNode = flower
    }

    // MARK: - Drawing Helpers

    private func createStemPath(height: CGFloat, curve: CGFloat, width: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: centerX, y: baseY))

        let endPoint = CGPoint(x: centerX + curve * 0.3, y: baseY + height)
        let controlPoint = CGPoint(x: centerX - curve, y: baseY + height * 0.5)

        path.addQuadCurve(to: endPoint, control: controlPoint)

        return path
    }

    private func createLeaf(at position: CGPoint, size: CGSize, angle: CGFloat, color: SKColor) -> SKShapeNode {
        // Pointed ellipse using 2 quad curves
        let path = CGMutablePath()

        let halfWidth = size.width / 2
        let halfHeight = size.height / 2

        path.move(to: CGPoint(x: -halfWidth, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: halfWidth, y: 0),
            control: CGPoint(x: 0, y: halfHeight)
        )
        path.addQuadCurve(
            to: CGPoint(x: -halfWidth, y: 0),
            control: CGPoint(x: 0, y: -halfHeight)
        )
        path.closeSubpath()

        let leaf = SKShapeNode(path: path)
        leaf.fillColor = color
        leaf.strokeColor = color.darker()
        leaf.lineWidth = 1.0
        leaf.position = position
        leaf.zRotation = angle

        return leaf
    }

    private func createBranch(from position: CGPoint, length: CGFloat, angle: CGFloat) -> SKShapeNode {
        let endX = position.x + cos(angle) * length
        let endY = position.y + sin(angle) * length

        let path = CGMutablePath()
        path.move(to: position)
        path.addLine(to: CGPoint(x: endX, y: endY))

        let branch = SKShapeNode(path: path)
        branch.strokeColor = SKColor(red: 0.35, green: 0.58, blue: 0.18, alpha: 1.0)
        branch.lineWidth = 2.5
        branch.lineCap = .round

        return branch
    }
}

// MARK: - SKColor Extension

private extension SKColor {

    var redComponent: CGFloat {
        var red: CGFloat = 0
        getRed(&red, green: nil, blue: nil, alpha: nil)
        return red
    }

    var greenComponent: CGFloat {
        var green: CGFloat = 0
        getRed(nil, green: &green, blue: nil, alpha: nil)
        return green
    }

    var blueComponent: CGFloat {
        var blue: CGFloat = 0
        getRed(nil, green: nil, blue: &blue, alpha: nil)
        return blue
    }

    func darker() -> SKColor {
        return SKColor(
            red: max(0, redComponent - 0.15),
            green: max(0, greenComponent - 0.15),
            blue: max(0, blueComponent - 0.15),
            alpha: 1.0
        )
    }
}
