import SpriteKit
import UIKit

// MARK: - ParticleEffects

/// Static factory methods that create SKEmitterNode instances programmatically.
/// No .sks files needed — textures are generated via UIGraphicsImageRenderer.
enum ParticleEffects {

    // MARK: - Water Drops

    /// Blue water drops falling from above with gravity.
    static func waterDrops() -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Texture: 12x16 white ellipse
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 16))
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: 12, height: 16))
        }
        emitter.particleTexture = SKTexture(image: image)

        emitter.particleBirthRate = 30
        emitter.numParticlesToEmit = 40
        emitter.particleLifetime = 1.2

        emitter.particleSpeed = 200
        emitter.yAcceleration = -300

        emitter.particleScale = 0.08

        emitter.particleColor = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .alpha

        return emitter
    }

    // MARK: - Sparkles

    /// Sparkles emitting in all directions. Default color is brand green (#8BC34A).
    static func sparkles(color: UIColor = UIColor(red: 0x8B / 255.0, green: 0xC3 / 255.0, blue: 0x4A / 255.0, alpha: 1.0)) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Texture: 10x10 circle
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: 10, height: 10))
        }
        emitter.particleTexture = SKTexture(image: image)

        emitter.particleBirthRate = 15
        emitter.numParticlesToEmit = 25
        emitter.particleLifetime = 1.5

        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 60
        emitter.yAcceleration = 20

        emitter.particleScale = 0.06

        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add

        return emitter
    }

    // MARK: - Stage Up Burst

    /// Gold burst for stage-up celebrations.
    static func stageUpBurst() -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Texture: 12x12 circle
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12))
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: 12, height: 12))
        }
        emitter.particleTexture = SKTexture(image: image)

        emitter.particleBirthRate = 80
        emitter.numParticlesToEmit = 60
        emitter.particleLifetime = 1.8

        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 120

        emitter.particleScale = 0.1

        // Gold (#FFD700)
        emitter.particleColor = UIColor(red: 1.0, green: 215.0 / 255.0, blue: 0.0, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add

        return emitter
    }

    // MARK: - Ambient Glow

    /// Very sparse green ambient glow particles that float upward slowly.
    static func ambientGlow() -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Texture: 8x8 circle
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        emitter.particleTexture = SKTexture(image: image)

        emitter.particleBirthRate = 3
        emitter.particleLifetime = 4.0

        emitter.particleSpeed = 15
        emitter.yAcceleration = 8

        emitter.particleScale = 0.04
        emitter.particleAlpha = 0.3

        // Brand green (#8BC34A)
        emitter.particleColor = UIColor(red: 0x8B / 255.0, green: 0xC3 / 255.0, blue: 0x4A / 255.0, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add

        return emitter
    }
}
