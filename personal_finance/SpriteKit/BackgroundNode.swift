//
//  BackgroundNode.swift
//  personal_finance
//
//  Created on 2026-02-18.
//

import SpriteKit
import UIKit

/// SpriteKit node that draws a vertical gradient sky background.
/// Changes color based on the plant's growth stage.
final class BackgroundNode: SKNode {

    // MARK: - Properties

    private let sceneSize: CGSize
    private var currentSprite: SKSpriteNode?
    private var isDarkMode: Bool = false
    private var currentStage: Int = 0

    // MARK: - Initialization

    init(sceneSize: CGSize) {
        self.sceneSize = sceneSize
        super.init()

        self.zPosition = 0

        // Render initial gradient (stage 0)
        let colors = gradientColors(for: 0)
        let texture = createGradientTexture(
            size: sceneSize,
            topColor: colors.top,
            bottomColor: colors.bottom
        )

        let sprite = SKSpriteNode(texture: texture)
        sprite.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        addChild(sprite)
        currentSprite = sprite

        setupClouds()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    /// Updates the background for the current color scheme (light/dark mode).
    func updateColorScheme(isDark: Bool) {
        guard isDark != isDarkMode else { return }
        isDarkMode = isDark
        updateForStage(currentStage, animated: true)
        // Update cloud opacity for dark mode
        children.compactMap { $0 as? SKNode }.forEach { node in
            // Clouds are SKNodes with SKShapeNode children (not SKSpriteNode)
            if node !== currentSprite && !(node is SKSpriteNode) {
                let targetAlpha: CGFloat = isDark ? 0.15 : node.userData?["originalAlpha"] as? CGFloat ?? 0.5
                node.run(.fadeAlpha(to: targetAlpha, duration: 0.5))
            }
        }
    }

    /// Updates the background gradient based on the plant's growth stage.
    /// - Parameters:
    ///   - stage: The plant's current growth stage (0-4+)
    ///   - animated: Whether to cross-fade to the new gradient
    func updateForStage(_ stage: Int, animated: Bool) {
        currentStage = stage
        let colors = gradientColors(for: stage)
        let texture = createGradientTexture(
            size: sceneSize,
            topColor: colors.top,
            bottomColor: colors.bottom
        )

        if animated {
            // Create new sprite at alpha 0
            let newSprite = SKSpriteNode(texture: texture)
            newSprite.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
            newSprite.alpha = 0
            addChild(newSprite)

            // Fade in new sprite over 1.0s
            let fadeIn = SKAction.fadeIn(withDuration: 1.0)
            newSprite.run(fadeIn)

            // Fade out old sprite over 1.0s then remove
            if let oldSprite = currentSprite {
                let fadeOut = SKAction.fadeOut(withDuration: 1.0)
                let remove = SKAction.removeFromParent()
                let sequence = SKAction.sequence([fadeOut, remove])
                oldSprite.run(sequence)
            }

            currentSprite = newSprite
        } else {
            // Replace immediately without animation
            currentSprite?.removeFromParent()

            let sprite = SKSpriteNode(texture: texture)
            sprite.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
            addChild(sprite)
            currentSprite = sprite
        }
    }

    // MARK: - Private Methods

    /// Returns the top and bottom colors for the gradient based on growth stage.
    /// - Parameter stage: The plant's growth stage
    /// - Returns: A tuple containing the top and bottom UIColors
    private func gradientColors(for stage: Int) -> (top: UIColor, bottom: UIColor) {
        switch stage {
        case 0:
            // Dreamy blush (#FFE4E1 → #FFF8DC)
            return (
                top: UIColor(red: 1.0, green: 0.894, blue: 0.882, alpha: 1.0),
                bottom: UIColor(red: 1.0, green: 0.973, blue: 0.863, alpha: 1.0)
            )
        case 1:
            // Soft lavender to mint (#E8D5F5 → #E8F5E9)
            return (
                top: UIColor(red: 0.91, green: 0.835, blue: 0.96, alpha: 1.0),
                bottom: UIColor(red: 0.91, green: 0.96, blue: 0.914, alpha: 1.0)
            )
        case 2:
            // Pastel sky to sage (#E0F0FF → #C8E6C9)
            return (
                top: UIColor(red: 0.878, green: 0.941, blue: 1.0, alpha: 1.0),
                bottom: UIColor(red: 0.784, green: 0.902, blue: 0.788, alpha: 1.0)
            )
        case 3:
            // Orchid to buttercream (#F3E5F5 → #FFF9C4)
            return (
                top: UIColor(red: 0.953, green: 0.898, blue: 0.961, alpha: 1.0),
                bottom: UIColor(red: 1.0, green: 0.976, blue: 0.769, alpha: 1.0)
            )
        default:
            // Stage 4+: Rose to peach (#FFE0E6 → #FFE0B2)
            return (
                top: UIColor(red: 1.0, green: 0.878, blue: 0.902, alpha: 1.0),
                bottom: UIColor(red: 1.0, green: 0.878, blue: 0.698, alpha: 1.0)
            )
        }
    }

    // MARK: - Cloud Decorations

    private func setupClouds() {
        // Cloud 1: left side, high, larger
        let cloud1 = createCloud(radius: 12)
        cloud1.position = CGPoint(x: sceneSize.width * 0.2, y: sceneSize.height * 0.82)
        cloud1.alpha = 0.6
        addChild(cloud1)
        animateCloudDrift(cloud1, range: 30, duration: 8)

        // Cloud 2: right side, mid-height
        let cloud2 = createCloud(radius: 10)
        cloud2.position = CGPoint(x: sceneSize.width * 0.75, y: sceneSize.height * 0.75)
        cloud2.alpha = 0.5
        addChild(cloud2)
        animateCloudDrift(cloud2, range: 25, duration: 10)

        // Cloud 3: center, highest, smallest
        let cloud3 = createCloud(radius: 8)
        cloud3.position = CGPoint(x: sceneSize.width * 0.5, y: sceneSize.height * 0.9)
        cloud3.alpha = 0.4
        addChild(cloud3)
        animateCloudDrift(cloud3, range: 20, duration: 12)
    }

    private func createCloud(radius: CGFloat) -> SKNode {
        let cloud = SKNode()
        let offsets: [(CGFloat, CGFloat, CGFloat)] = [
            (0, 0, radius),
            (-radius * 0.8, -radius * 0.2, radius * 0.7),
            (radius * 0.8, -radius * 0.1, radius * 0.75),
            (0, radius * 0.4, radius * 0.6),
        ]
        for (dx, dy, r) in offsets {
            let circle = SKShapeNode(circleOfRadius: r)
            circle.fillColor = .white
            circle.strokeColor = .clear
            circle.position = CGPoint(x: dx, y: dy)
            cloud.addChild(circle)
        }
        return cloud
    }

    private func animateCloudDrift(_ cloud: SKNode, range: CGFloat, duration: TimeInterval) {
        let moveRight = SKAction.moveBy(x: range, y: 0, duration: duration)
        let moveLeft = SKAction.moveBy(x: -range, y: 0, duration: duration)
        moveRight.timingMode = .easeInEaseOut
        moveLeft.timingMode = .easeInEaseOut
        cloud.run(.repeatForever(.sequence([moveRight, moveLeft])))
    }

    /// Creates a vertical gradient texture using Core Graphics.
    /// - Parameters:
    ///   - size: The size of the texture
    ///   - topColor: The color at the top of the gradient
    ///   - bottomColor: The color at the bottom of the gradient
    /// - Returns: An SKTexture containing the gradient
    private func createGradientTexture(
        size: CGSize,
        topColor: UIColor,
        bottomColor: UIColor
    ) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let cgContext = context.cgContext

            // Create gradient
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [topColor.cgColor, bottomColor.cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]

            guard let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: colors,
                locations: locations
            ) else {
                return
            }

            // Draw gradient from top to bottom
            let startPoint = CGPoint(x: size.width / 2, y: size.height)
            let endPoint = CGPoint(x: size.width / 2, y: 0)

            cgContext.drawLinearGradient(
                gradient,
                start: startPoint,
                end: endPoint,
                options: []
            )
        }

        return SKTexture(image: image)
    }
}
