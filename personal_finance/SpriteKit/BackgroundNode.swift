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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    /// Updates the background gradient based on the plant's growth stage.
    /// - Parameters:
    ///   - stage: The plant's current growth stage (0-4+)
    ///   - animated: Whether to cross-fade to the new gradient
    func updateForStage(_ stage: Int, animated: Bool) {
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
            // Warm sunrise
            return (
                top: UIColor(red: 0.98, green: 0.85, blue: 0.65, alpha: 1.0),
                bottom: UIColor(red: 0.95, green: 0.92, blue: 0.82, alpha: 1.0)
            )
        case 1:
            // Early morning
            return (
                top: UIColor(red: 0.75, green: 0.90, blue: 0.95, alpha: 1.0),
                bottom: UIColor(red: 0.90, green: 0.95, blue: 0.88, alpha: 1.0)
            )
        case 2:
            // Bright day
            return (
                top: UIColor(red: 0.55, green: 0.82, blue: 0.95, alpha: 1.0),
                bottom: UIColor(red: 0.85, green: 0.95, blue: 0.85, alpha: 1.0)
            )
        case 3:
            // Lush afternoon
            return (
                top: UIColor(red: 0.45, green: 0.75, blue: 0.92, alpha: 1.0),
                bottom: UIColor(red: 0.78, green: 0.93, blue: 0.78, alpha: 1.0)
            )
        default:
            // Stage 4+: Golden hour
            return (
                top: UIColor(red: 1.0, green: 0.85, blue: 0.55, alpha: 1.0),
                bottom: UIColor(red: 0.95, green: 0.95, blue: 0.80, alpha: 1.0)
            )
        }
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
