//
//  GroundNode.swift
//  personal_finance
//

import SpriteKit

final class GroundNode: SKNode {
    private let sceneSize: CGSize

    init(sceneSize: CGSize) {
        self.sceneSize = sceneSize
        super.init()
        self.zPosition = 1
        setupGrassHill()
        setupFlowerDecorations()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupGrassHill() {
        let w = sceneSize.width
        let hillY = sceneSize.height * 0.18

        // Soft green grass hill
        let hillPath = CGMutablePath()
        hillPath.move(to: CGPoint(x: 0, y: 0))
        hillPath.addLine(to: CGPoint(x: 0, y: hillY * 0.5))
        hillPath.addQuadCurve(
            to: CGPoint(x: w, y: hillY * 0.5),
            control: CGPoint(x: w / 2, y: hillY * 1.15)
        )
        hillPath.addLine(to: CGPoint(x: w, y: 0))
        hillPath.closeSubpath()

        let hill = SKShapeNode(path: hillPath)
        hill.fillColor = SKColor(red: 0.6, green: 0.82, blue: 0.5, alpha: 1.0)
        hill.strokeColor = SKColor(red: 0.5, green: 0.72, blue: 0.4, alpha: 1.0)
        hill.lineWidth = 2.0
        addChild(hill)

        // Lighter grass highlight on top
        let highlightPath = CGMutablePath()
        highlightPath.move(to: CGPoint(x: w * 0.15, y: hillY * 0.55))
        highlightPath.addQuadCurve(
            to: CGPoint(x: w * 0.85, y: hillY * 0.55),
            control: CGPoint(x: w / 2, y: hillY * 1.05)
        )
        let highlight = SKShapeNode(path: highlightPath)
        highlight.strokeColor = SKColor(red: 0.7, green: 0.88, blue: 0.6, alpha: 0.6)
        highlight.lineWidth = 3.0
        highlight.lineCap = .round
        highlight.fillColor = .clear
        addChild(highlight)
    }

    private func setupFlowerDecorations() {
        let hillY = sceneSize.height * 0.18

        let flowerData: [(CGFloat, CGFloat, SKColor)] = [
            (sceneSize.width * 0.15, hillY * 0.7, SKColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 0.8)),
            (sceneSize.width * 0.82, hillY * 0.65, SKColor(red: 0.8, green: 0.7, blue: 1.0, alpha: 0.8)),
            (sceneSize.width * 0.35, hillY * 0.85, SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 0.8)),
            (sceneSize.width * 0.7, hillY * 0.8, SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.8)),
        ]

        for (x, y, color) in flowerData {
            let flower = createTinyFlower(color: color)
            flower.position = CGPoint(x: x, y: y)
            addChild(flower)
        }
    }

    private func createTinyFlower(color: SKColor) -> SKNode {
        let node = SKNode()
        let petalRadius: CGFloat = 3
        let offsets: [(CGFloat, CGFloat)] = [(0, petalRadius), (0, -petalRadius), (petalRadius, 0), (-petalRadius, 0)]
        for (dx, dy) in offsets {
            let petal = SKShapeNode(circleOfRadius: petalRadius)
            petal.fillColor = color
            petal.strokeColor = .clear
            petal.position = CGPoint(x: dx, y: dy)
            node.addChild(petal)
        }
        let center = SKShapeNode(circleOfRadius: 2)
        center.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1.0)
        center.strokeColor = .clear
        center.zPosition = 0.1
        node.addChild(center)
        return node
    }
}
