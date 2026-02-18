//
//  SproutScene.swift
//  personal_finance
//
//  Created on 2026-02-18.
//

import SpriteKit

final class SproutScene: SKScene {

    // MARK: - Properties

    private var backgroundNode: BackgroundNode?
    private var groundNode: GroundNode?
    private var potNode: PotNode?
    private var plantNode: PlantNode?
    private var ambientEmitter: SKEmitterNode?
    private var currentStage: Int = -1

    // Touch tracking
    private var tapCount = 0
    private var tapResetTimer: Timer?
    private var longPressTimer: Timer?
    private var speechBubbleNode: SKNode?

    // Blink timer
    private var blinkTimer: Timer?

    // Speech bubble texts
    private let normalPhrases = ["嗨嗨~", "好開心", "再來一次~", "謝謝澆水", "好想長大", "你好呀~"]
    private let stage4Phrases = ["我開花了耶!", "好漂亮~", "謝謝你的照顧"]

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = .clear
        scaleMode = .aspectFit

        let background = BackgroundNode(sceneSize: size)
        addChild(background)
        backgroundNode = background

        let ground = GroundNode(sceneSize: size)
        addChild(ground)
        groundNode = ground

        let pot = PotNode(sceneSize: size)
        addChild(pot)
        potNode = pot

        let plant = PlantNode(sceneSize: size)
        addChild(plant)
        plantNode = plant

        let ambient = ParticleEffects.kawaiiAmbient()
        ambient.position = CGPoint(x: size.width / 2, y: size.height * 0.5)
        ambient.zPosition = 3
        ambient.particlePositionRange = CGVector(dx: size.width * 0.7, dy: size.height * 0.5)
        addChild(ambient)
        ambientEmitter = ambient

        startBlinkTimer()
    }

    override func willMove(from view: SKView) {
        blinkTimer?.invalidate()
        blinkTimer = nil
    }

    // MARK: - Blink Timer

    private func startBlinkTimer() {
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            self?.potNode?.playBlink()
            AudioService.shared.play(.blink)
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let _ = touches.first else { return }

        longPressTimer?.invalidate()
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.handleLongPress()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        longPressTimer?.invalidate()
        longPressTimer = nil

        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        handleTap(at: location)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        longPressTimer?.invalidate()
        longPressTimer = nil
    }

    private func handleTap(at location: CGPoint) {
        tapCount += 1
        tapResetTimer?.invalidate()
        tapResetTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
            self?.tapCount = 0
        }

        AudioService.shared.play(.tap)

        if tapCount >= 3 {
            // Triple tap: jump + star explosion
            potNode?.playJumpReaction()
            let stars = ParticleEffects.stars()
            stars.position = CGPoint(x: size.width / 2, y: size.height * 0.5)
            stars.zPosition = 3
            addChild(stars)
            run(.sequence([
                .wait(forDuration: 1.5),
                .run { stars.particleBirthRate = 0 },
                .wait(forDuration: 2.0),
                .run { stars.removeFromParent() }
            ]))
            tapCount = 0
        } else {
            potNode?.playTapReaction()

            let hearts = ParticleEffects.hearts()
            hearts.position = location
            hearts.zPosition = 3
            addChild(hearts)
            run(.sequence([
                .wait(forDuration: 2.0),
                .run { hearts.particleBirthRate = 0 },
                .wait(forDuration: 2.0),
                .run { hearts.removeFromParent() }
            ]))

            showSpeechBubble()
        }
    }

    private func handleLongPress() {
        potNode?.playLongPressReaction()
        AudioService.shared.play(.tap)

        let hearts = ParticleEffects.hearts()
        hearts.position = CGPoint(x: size.width / 2, y: size.height * 0.5)
        hearts.zPosition = 3
        hearts.particleBirthRate = 10
        hearts.numParticlesToEmit = 15
        addChild(hearts)
        run(.sequence([
            .wait(forDuration: 2.5),
            .run { hearts.particleBirthRate = 0 },
            .wait(forDuration: 2.0),
            .run { hearts.removeFromParent() }
        ]))
    }

    // MARK: - Speech Bubble

    private func showSpeechBubble() {
        speechBubbleNode?.removeFromParent()

        let phrases = currentStage >= 4 ? stage4Phrases : normalPhrases
        let text = phrases.randomElement() ?? "嗨嗨~"

        let bubble = SKNode()
        bubble.zPosition = 5

        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 14
        label.fontColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)

        let padding: CGFloat = 12
        let bgWidth = label.frame.width + padding * 2
        let bgHeight: CGFloat = 28

        let bgRect = CGRect(x: -bgWidth / 2, y: -bgHeight / 2, width: bgWidth, height: bgHeight)
        let bg = SKShapeNode(rect: bgRect, cornerRadius: bgHeight / 2)
        bg.fillColor = .white
        bg.strokeColor = SKColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        bg.lineWidth = 1.0
        bg.alpha = 0.9
        bubble.addChild(bg)

        label.position = CGPoint(x: 0, y: -5)
        bubble.addChild(label)

        bubble.position = CGPoint(x: size.width / 2, y: size.height * 0.65)
        bubble.alpha = 0
        addChild(bubble)
        speechBubbleNode = bubble

        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let moveUp = SKAction.moveBy(x: 0, y: 15, duration: 1.8)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()

        bubble.run(.sequence([fadeIn, .group([moveUp, .sequence([.wait(forDuration: 1.5), fadeOut])]), remove]))
    }

    // MARK: - Public API

    func configure(stage: Int, growthPoints: Int) {
        guard stage != currentStage else { return }

        let animated = currentStage >= 0
        currentStage = stage

        plantNode?.morphTo(stage: stage, animated: animated)
        backgroundNode?.updateForStage(stage, animated: animated)
    }

    func playWaterAnimation(pointsEarned: Int, completion: (() -> Void)? = nil) {
        AudioService.shared.play(.waterDrop)

        let waterDrops = ParticleEffects.waterDrops()
        waterDrops.position = CGPoint(x: size.width / 2, y: size.height * 0.85)
        waterDrops.zPosition = 3
        waterDrops.particlePositionRange = CGVector(dx: 80, dy: 0)
        addChild(waterDrops)
        run(.sequence([
            .wait(forDuration: 1.5),
            .run { waterDrops.particleBirthRate = 0 },
            .wait(forDuration: 1.5),
            .run { waterDrops.removeFromParent() }
        ]))

        run(.sequence([
            .wait(forDuration: 0.5),
            .run { [weak self] in
                self?.potNode?.setExpression(.happy, animated: true)
                self?.plantNode?.playGrowthSpurt()
                AudioService.shared.play(.grow)
            }
        ]))

        run(.sequence([
            .wait(forDuration: 1.0),
            .run { [weak self] in
                guard let self else { return }
                let stars = ParticleEffects.stars()
                stars.position = CGPoint(x: self.size.width / 2, y: self.size.height * 0.55)
                stars.zPosition = 3
                self.addChild(stars)
                self.run(.sequence([
                    .wait(forDuration: 1.5),
                    .run { stars.particleBirthRate = 0 },
                    .wait(forDuration: 2.0),
                    .run { stars.removeFromParent() }
                ]))
            }
        ]))

        run(.sequence([
            .wait(forDuration: 1.5),
            .run { [weak self] in
                guard let self else { return }
                let pointsLabel = SKLabelNode(text: "+\(pointsEarned) 點")
                pointsLabel.fontName = "AvenirNext-Bold"
                pointsLabel.fontSize = 18
                pointsLabel.fontColor = SKColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
                pointsLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height * 0.6)
                pointsLabel.zPosition = 5
                self.addChild(pointsLabel)

                let floatUp = SKAction.moveBy(x: 0, y: 30, duration: 1.0)
                let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                pointsLabel.run(.sequence([
                    .group([floatUp, .sequence([.wait(forDuration: 0.5), fadeOut])]),
                    .removeFromParent()
                ]))
            }
        ]))

        run(.sequence([
            .wait(forDuration: 2.5),
            .run { [weak self] in
                self?.potNode?.setExpression(.expecting, animated: false)
                completion?()
            }
        ]))
    }

    func playStageUpAnimation(newStage: Int, completion: (() -> Void)? = nil) {
        AudioService.shared.play(.stageUp)

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

        potNode?.setExpression(.surprised, animated: true)

        run(.sequence([
            .wait(forDuration: 0.2),
            .run { [weak self] in
                guard let self else { return }
                self.currentStage = newStage
                self.plantNode?.morphTo(stage: newStage, animated: true)
                self.backgroundNode?.updateForStage(newStage, animated: true)

                let confetti = ParticleEffects.confetti()
                confetti.position = CGPoint(x: self.size.width / 2, y: self.size.height * 0.55)
                confetti.zPosition = 3
                self.addChild(confetti)
                self.run(.sequence([
                    .wait(forDuration: 1.0),
                    .run { confetti.particleBirthRate = 0 },
                    .wait(forDuration: 2.5),
                    .run { confetti.removeFromParent() }
                ]))
            }
        ]))

        run(.sequence([
            .wait(forDuration: 1.5),
            .run { [weak self] in
                guard let self else { return }
                let levelLabel = SKLabelNode(text: "等級提升！Lv \(newStage)")
                levelLabel.fontName = "AvenirNext-Bold"
                levelLabel.fontSize = 20
                levelLabel.fontColor = SKColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0)
                levelLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height * 0.65)
                levelLabel.zPosition = 5
                self.addChild(levelLabel)

                let scaleUp = SKAction.scale(to: 1.3, duration: 0.2)
                let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
                let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                levelLabel.run(.sequence([
                    scaleUp, scaleDown,
                    .wait(forDuration: 0.8),
                    fadeOut,
                    .removeFromParent()
                ]))
            }
        ]))

        run(.sequence([
            .wait(forDuration: 3.0),
            .run { [weak self] in
                self?.potNode?.setExpression(.expecting, animated: false)
                completion?()
            }
        ]))
    }

    /// Set expression externally (e.g., sleeping when already watered)
    func setExpression(_ expression: PotNode.Expression) {
        potNode?.setExpression(expression, animated: true)
    }
}
