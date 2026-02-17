//
//  GroundNode.swift
//  personal_finance
//
//  Created on 2026-02-18.
//

import SpriteKit

final class GroundNode: SKNode {
    private let sceneSize: CGSize

    init(sceneSize: CGSize) {
        self.sceneSize = sceneSize
        super.init()
        self.zPosition = 1
        setupGround()
        setupPot()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupGround() {
        let w = sceneSize.width
        let groundY = sceneSize.height * 0.22

        // Ground filled shape
        let groundPath = CGMutablePath()
        groundPath.move(to: CGPoint(x: 0, y: 0))
        groundPath.addLine(to: CGPoint(x: 0, y: groundY * 0.6))
        groundPath.addQuadCurve(
            to: CGPoint(x: w, y: groundY * 0.6),
            control: CGPoint(x: w / 2, y: groundY * 1.1)
        )
        groundPath.addLine(to: CGPoint(x: w, y: 0))
        groundPath.closeSubpath()

        let groundShape = SKShapeNode(path: groundPath)
        groundShape.fillColor = UIColor(red: 0.55, green: 0.38, blue: 0.22, alpha: 1.0)
        groundShape.strokeColor = UIColor(red: 0.45, green: 0.30, blue: 0.18, alpha: 1.0)
        groundShape.lineWidth = 1.5
        addChild(groundShape)

        // Grass line on top
        let grassPath = CGMutablePath()
        grassPath.move(to: CGPoint(x: 0, y: groundY * 0.6))
        grassPath.addQuadCurve(
            to: CGPoint(x: w, y: groundY * 0.6),
            control: CGPoint(x: w / 2, y: groundY * 1.1)
        )

        let grassLine = SKShapeNode(path: grassPath)
        grassLine.strokeColor = UIColor(red: 0.4, green: 0.65, blue: 0.2, alpha: 1.0)
        grassLine.lineWidth = 4
        grassLine.lineCap = .round
        grassLine.fillColor = .clear
        addChild(grassLine)
    }

    private func setupPot() {
        let centerX = sceneSize.width / 2
        let baseY = sceneSize.height * 0.22

        let potWidth: CGFloat = 80
        let topHalf: CGFloat = 40
        let bottomHalf = potWidth * 0.35
        let potHeight: CGFloat = 55

        // Pot trapezoid shape
        let potPath = CGMutablePath()
        potPath.move(to: CGPoint(x: centerX - topHalf, y: baseY + potHeight))
        potPath.addLine(to: CGPoint(x: centerX - bottomHalf, y: baseY))
        potPath.addLine(to: CGPoint(x: centerX + bottomHalf, y: baseY))
        potPath.addLine(to: CGPoint(x: centerX + topHalf, y: baseY + potHeight))
        potPath.closeSubpath()

        let potShape = SKShapeNode(path: potPath)
        potShape.fillColor = UIColor(red: 0.76, green: 0.50, blue: 0.32, alpha: 1.0)
        potShape.strokeColor = UIColor(red: 0.60, green: 0.38, blue: 0.22, alpha: 1.0)
        potShape.lineWidth = 1.5
        addChild(potShape)

        // Pot rim
        let rimWidth = topHalf + 2.5
        let rimHeight: CGFloat = 8

        let rimPath = CGMutablePath()
        rimPath.move(to: CGPoint(x: centerX - rimWidth, y: baseY + potHeight))
        rimPath.addLine(to: CGPoint(x: centerX - topHalf, y: baseY + potHeight + rimHeight))
        rimPath.addLine(to: CGPoint(x: centerX + topHalf, y: baseY + potHeight + rimHeight))
        rimPath.addLine(to: CGPoint(x: centerX + rimWidth, y: baseY + potHeight))
        rimPath.closeSubpath()

        let rimShape = SKShapeNode(path: rimPath)
        rimShape.fillColor = UIColor(red: 0.70, green: 0.46, blue: 0.28, alpha: 1.0)
        rimShape.strokeColor = UIColor(red: 0.60, green: 0.38, blue: 0.22, alpha: 1.0)
        rimShape.lineWidth = 1.5
        addChild(rimShape)

        // Soil ellipse
        let soilWidth = topHalf * 2
        let soilHeight: CGFloat = 12

        let soilShape = SKShapeNode(ellipseOf: CGSize(width: soilWidth, height: soilHeight))
        soilShape.position = CGPoint(x: centerX, y: baseY + potHeight + rimHeight - 2)
        soilShape.fillColor = UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
        soilShape.strokeColor = .clear
        soilShape.zPosition = 0.1
        addChild(soilShape)
    }
}
