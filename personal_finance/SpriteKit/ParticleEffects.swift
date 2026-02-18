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

    // MARK: - Hearts

    /// Small floating heart particles for kawaii celebrations.
    static func hearts() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 16, height: 14))
        let image = renderer.image { ctx in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 8, y: 14))
            path.addCurve(to: CGPoint(x: 0, y: 4), controlPoint1: CGPoint(x: 2, y: 10), controlPoint2: CGPoint(x: 0, y: 7))
            path.addArc(withCenter: CGPoint(x: 4, y: 4), radius: 4, startAngle: .pi, endAngle: 0, clockwise: true)
            path.addArc(withCenter: CGPoint(x: 12, y: 4), radius: 4, startAngle: .pi, endAngle: 0, clockwise: true)
            path.addCurve(to: CGPoint(x: 8, y: 14), controlPoint1: CGPoint(x: 16, y: 7), controlPoint2: CGPoint(x: 14, y: 10))
            UIColor.white.setFill()
            path.fill()
        }
        emitter.particleTexture = SKTexture(image: image)
        emitter.particleBirthRate = 5
        emitter.numParticlesToEmit = 8
        emitter.particleLifetime = 2.0
        emitter.emissionAngleRange = .pi / 3
        emitter.emissionAngle = .pi / 2
        emitter.particleSpeed = 30
        emitter.yAcceleration = 10
        emitter.particleScale = 0.06
        emitter.particleScaleRange = 0.02
        emitter.particleColor = UIColor(red: 1.0, green: 0.5, blue: 0.6, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .alpha
        return emitter
    }

    // MARK: - Stars

    /// Gold star sparkles for achievements.
    static func stars() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12))
        let image = renderer.image { ctx in
            let path = UIBezierPath()
            let center = CGPoint(x: 6, y: 6)
            let outerR: CGFloat = 6
            let innerR: CGFloat = 2.5
            for i in 0..<8 {
                let angle = CGFloat(i) * .pi / 4 - .pi / 2
                let r = i % 2 == 0 ? outerR : innerR
                let point = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.close()
            UIColor.white.setFill()
            path.fill()
        }
        emitter.particleTexture = SKTexture(image: image)
        emitter.particleBirthRate = 20
        emitter.numParticlesToEmit = 30
        emitter.particleLifetime = 1.5
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 80
        emitter.yAcceleration = -20
        emitter.particleScale = 0.08
        emitter.particleScaleRange = 0.04
        emitter.particleColor = UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add
        return emitter
    }

    // MARK: - Confetti

    /// Rainbow confetti burst for celebrations.
    static func confetti() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 12))
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 1, y: 1, width: 6, height: 10))
        }
        emitter.particleTexture = SKTexture(image: image)
        emitter.particleBirthRate = 60
        emitter.numParticlesToEmit = 80
        emitter.particleLifetime = 2.5
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 100
        emitter.yAcceleration = -80
        emitter.particleScale = 0.06
        emitter.particleScaleRange = 0.03
        emitter.particleRotation = 0
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = .pi
        emitter.particleColorSequence = nil
        emitter.particleColor = UIColor(red: 1.0, green: 0.6, blue: 0.7, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorRedRange = 0.5
        emitter.particleColorGreenRange = 0.5
        emitter.particleColorBlueRange = 0.5
        emitter.particleBlendMode = .alpha
        return emitter
    }

    // MARK: - Kawaii Ambient

    /// Dreamy multi-color ambient particles with soft pastel tones.
    static func kawaiiAmbient() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        emitter.particleTexture = SKTexture(image: image)
        emitter.particleBirthRate = 4
        emitter.particleLifetime = 5.0
        emitter.particleSpeed = 10
        emitter.yAcceleration = 5
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.04
        emitter.particleScaleRange = 0.02
        emitter.particleAlpha = 0.35
        emitter.particleAlphaRange = 0.15
        emitter.particleColor = UIColor(red: 1.0, green: 0.8, blue: 0.9, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorRedRange = 0.3
        emitter.particleColorGreenRange = 0.2
        emitter.particleColorBlueRange = 0.3
        emitter.particleBlendMode = .add
        return emitter
    }
}
