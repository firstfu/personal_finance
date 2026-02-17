//
//  SproutScene.swift
//  personal_finance
//
//  Created on 2026-02-18.
//

import SpriteKit

/// Main SKScene orchestrator that ties all layers together
/// and provides the public API for SwiftUI to drive the sprout visualization.
final class SproutScene: SKScene {

    // MARK: - Private Properties

    private var backgroundNode: BackgroundNode?
    private var groundNode: GroundNode?
    private var plantNode: PlantNode?
    private var ambientEmitter: SKEmitterNode?
    private var currentStage: Int = -1

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        // Configure scene
        backgroundColor = .clear
        scaleMode = .aspectFit

        // Create and add background layer
        let background = BackgroundNode(sceneSize: size)
        addChild(background)
        backgroundNode = background

        // Create and add ground layer
        let ground = GroundNode(sceneSize: size)
        addChild(ground)
        groundNode = ground

        // Create and add plant layer
        let plant = PlantNode(sceneSize: size)
        addChild(plant)
        plantNode = plant

        // Create and add ambient glow particles
        let ambient = ParticleEffects.ambientGlow()
        ambient.position = CGPoint(x: size.width / 2, y: size.height * 0.5)
        ambient.zPosition = 3
        ambient.particlePositionRange = CGVector(dx: size.width * 0.6, dy: size.height * 0.4)
        addChild(ambient)
        ambientEmitter = ambient
    }

    // MARK: - Public API

    /// Configure the scene for a specific stage and growth points
    /// - Parameters:
    ///   - stage: The growth stage (0-6)
    ///   - growthPoints: Current growth points within the stage
    func configure(stage: Int, growthPoints: Int) {
        guard stage != currentStage else { return }

        let animated = currentStage >= 0
        currentStage = stage

        plantNode?.morphTo(stage: stage, animated: animated)
        backgroundNode?.updateForStage(stage, animated: animated)
    }

    /// Play watering animation sequence
    /// - Parameters:
    ///   - pointsEarned: Number of points earned (unused but kept for future use)
    ///   - completion: Optional callback when animation completes
    func playWaterAnimation(pointsEarned: Int, completion: (() -> Void)? = nil) {
        // Phase 1 (0s): Water drops from top
        let waterDrops = ParticleEffects.waterDrops()
        waterDrops.position = CGPoint(x: size.width / 2, y: size.height * 0.85)
        waterDrops.zPosition = 3
        waterDrops.particlePositionRange = CGVector(dx: 80, dy: 0)
        addChild(waterDrops)

        // Stop birth rate after 1.5s, remove after 3s
        run(.sequence([
            .wait(forDuration: 1.5),
            .run { waterDrops.particleBirthRate = 0 },
            .wait(forDuration: 1.5),
            .run { waterDrops.removeFromParent() }
        ]))

        // Phase 2 (0.5s delay): Growth spurt
        run(.sequence([
            .wait(forDuration: 0.5),
            .run { [weak self] in
                self?.plantNode?.playGrowthSpurt()
            }
        ]))

        // Phase 3 (1.5s delay): Sparkles
        run(.sequence([
            .wait(forDuration: 1.5),
            .run { [weak self] in
                guard let self else { return }
                let sparkles = ParticleEffects.sparkles()
                sparkles.position = CGPoint(x: self.size.width / 2, y: self.size.height * 0.55)
                sparkles.zPosition = 3
                self.addChild(sparkles)

                // Stop after 1.5s, remove after 3.5s
                self.run(.sequence([
                    .wait(forDuration: 1.5),
                    .run { sparkles.particleBirthRate = 0 },
                    .wait(forDuration: 2.0),
                    .run { sparkles.removeFromParent() }
                ]))
            }
        ]))

        // Completion callback after 2.5s
        if let completion {
            run(.sequence([
                .wait(forDuration: 2.5),
                .run(completion)
            ]))
        }
    }

    /// Play stage-up animation sequence
    /// - Parameters:
    ///   - newStage: The new stage to transition to
    ///   - completion: Optional callback when animation completes
    func playStageUpAnimation(newStage: Int, completion: (() -> Void)? = nil) {
        // Phase 1 (0s): Flash white
        let flash = SKShapeNode(rectOf: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.zPosition = 10
        flash.alpha = 0
        addChild(flash)

        flash.run(.sequence([
            .fadeAlpha(to: 0.6, duration: 0.1),
            .fadeOut(withDuration: 0.3),
            .removeFromParent()
        ]))

        // Phase 2 (0.2s): Update stage
        run(.sequence([
            .wait(forDuration: 0.2),
            .run { [weak self] in
                self?.currentStage = newStage
                self?.plantNode?.morphTo(stage: newStage, animated: true)
                self?.backgroundNode?.updateForStage(newStage, animated: true)
            }
        ]))

        // Phase 3 (0.5s): Stage-up burst
        run(.sequence([
            .wait(forDuration: 0.5),
            .run { [weak self] in
                guard let self else { return }
                let burst = ParticleEffects.stageUpBurst()
                burst.position = CGPoint(x: self.size.width / 2, y: self.size.height * 0.55)
                burst.zPosition = 3
                self.addChild(burst)

                // Stop after 0.8s, remove after 2.8s
                self.run(.sequence([
                    .wait(forDuration: 0.8),
                    .run { burst.particleBirthRate = 0 },
                    .wait(forDuration: 2.0),
                    .run { burst.removeFromParent() }
                ]))
            }
        ]))

        // Completion callback after 3.0s
        if let completion {
            run(.sequence([
                .wait(forDuration: 3.0),
                .run(completion)
            ]))
        }
    }
}
