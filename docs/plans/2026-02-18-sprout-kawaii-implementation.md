# Sprout Kawaii Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform the sprout feature from realistic plant style to a kawaii potted-plant pet with dreamy backgrounds, cute sound effects, tap interactions, and speech bubbles.

**Architecture:** Keep existing SpriteKit-based architecture. Replace visual content of all SpriteKit nodes (PlantNode, GroundNode, BackgroundNode, ParticleEffects) with kawaii cartoon style. Add new PotNode for cute pot with expression system. Add new AudioService using AVAudioEngine for programmatic sound synthesis. Integrate touch interactions and speech bubbles into SproutScene. Update SproutTabView UI to match dreamy kawaii aesthetic.

**Tech Stack:** SpriteKit (SKShapeNode bezier curves), AVAudioEngine + AVAudioSourceNode (sound synthesis), SwiftUI, SwiftData (no changes to models)

**Design doc:** `docs/plans/2026-02-18-sprout-kawaii-redesign-design.md`

---

### Task 1: Create AudioService — Sound Synthesis Engine

**Files:**
- Create: `personal_finance/Services/AudioService.swift`

This is the foundation for all audio. Build the AVAudioEngine-based synthesizer that generates cute 8-bit sounds programmatically.

**Step 1: Create AudioService.swift with basic structure**

```swift
//
//  AudioService.swift
//  personal_finance
//

import AVFoundation
import SwiftUI

/// Programmatic sound synthesis engine using AVAudioEngine.
/// Generates cute 8-bit style sound effects and a simple BGM loop.
final class AudioService {
    static let shared = AudioService()

    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?

    @AppStorage("soundEffectsEnabled") var soundEffectsEnabled = true
    @AppStorage("backgroundMusicEnabled") var backgroundMusicEnabled = true

    // Audio format: 44100 Hz, mono, float32
    private let sampleRate: Double = 44100
    private lazy var audioFormat = AVAudioFormat(
        standardFormatWithSampleRate: sampleRate,
        channels: 1
    )!

    private init() {
        setupEngine()
    }

    // MARK: - Engine Setup

    private func setupEngine() {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: audioFormat)

        do {
            try engine.start()
        } catch {
            print("AudioService: Failed to start engine: \(error)")
        }

        self.engine = engine
        self.playerNode = player
    }

    // MARK: - Sound Effect Playback

    func play(_ effect: SoundEffect) {
        guard soundEffectsEnabled else { return }
        guard let player = playerNode, let engine = engine else { return }

        if !engine.isRunning {
            try? engine.start()
        }

        let buffer = generateBuffer(for: effect)
        player.stop()
        player.scheduleBuffer(buffer)
        player.play()
    }

    // MARK: - Buffer Generation

    private func generateBuffer(for effect: SoundEffect) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(effect.duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let normalizedT = t / effect.duration
            data[i] = Float(effect.waveform(t, normalizedT) * effect.envelope(normalizedT) * 0.3)
        }

        return buffer
    }
}

// MARK: - Sound Effects

enum SoundEffect {
    case waterDrop
    case grow
    case stageUp
    case harvest
    case tap
    case blink

    var duration: Double {
        switch self {
        case .waterDrop: return 0.3
        case .grow: return 0.4
        case .stageUp: return 0.6
        case .harvest: return 0.8
        case .tap: return 0.12
        case .blink: return 0.05
        }
    }

    /// Waveform generator: t = absolute time, normalizedT = 0...1
    var waveform: (Double, Double) -> Double {
        switch self {
        case .waterDrop:
            // Sine wave descending from 800Hz to 200Hz
            return { t, nt in
                let freq = 800 - 600 * nt
                return sin(2 * .pi * freq * t)
            }
        case .grow:
            // Triangle wave ascending from 300Hz to 600Hz
            return { t, nt in
                let freq = 300 + 300 * nt
                let phase = freq * t
                let frac = phase - floor(phase)
                return frac < 0.5 ? (4 * frac - 1) : (3 - 4 * frac)
            }
        case .stageUp:
            // Do-Mi-Sol arpeggio (C5-E5-G5)
            return { t, nt in
                let freq: Double
                if nt < 0.33 { freq = 523.25 } // C5
                else if nt < 0.66 { freq = 659.25 } // E5
                else { freq = 783.99 } // G5
                return sin(2 * .pi * freq * t)
            }
        case .harvest:
            // Rising arpeggio C5-E5-G5-C6
            return { t, nt in
                let freq: Double
                if nt < 0.25 { freq = 523.25 }
                else if nt < 0.5 { freq = 659.25 }
                else if nt < 0.75 { freq = 783.99 }
                else { freq = 1046.5 }
                return sin(2 * .pi * freq * t)
            }
        case .tap:
            // Short sine "boop" at 400Hz
            return { t, _ in
                sin(2 * .pi * 400 * t)
            }
        case .blink:
            // Very short filtered noise-like chirp
            return { t, _ in
                sin(2 * .pi * 1200 * t) * sin(2 * .pi * 80 * t)
            }
        }
    }

    /// Amplitude envelope: normalizedT = 0...1
    var envelope: (Double) -> Double {
        switch self {
        case .waterDrop:
            return { nt in max(0, 1 - nt * 1.2) }
        case .grow:
            return { nt in nt < 0.1 ? nt * 10 : max(0, 1 - (nt - 0.1) / 0.9) }
        case .stageUp:
            return { nt in
                let segment = nt * 3
                let segFrac = segment - floor(segment)
                return segFrac < 0.05 ? segFrac * 20 : max(0.2, 1 - segFrac * 0.8)
            }
        case .harvest:
            return { nt in
                let segment = nt * 4
                let segFrac = segment - floor(segment)
                return segFrac < 0.05 ? segFrac * 20 : max(0.3, 1 - segFrac * 0.7)
            }
        case .tap:
            return { nt in max(0, 1 - nt * 2) }
        case .blink:
            return { nt in max(0, 1 - nt * 3) }
        }
    }
}
```

**Step 2: Add AudioService.swift to Xcode project**

The file is in `personal_finance/Services/` directory alongside `SproutGrowthService.swift`. Xcode should auto-detect it.

**Step 3: Build to verify compilation**

Run:
```bash
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build
```
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add personal_finance/Services/AudioService.swift
git commit -m "feat: add AudioService with programmatic 8-bit sound synthesis"
```

---

### Task 2: Create PotNode — Cute Pot with Expression System

**Files:**
- Create: `personal_finance/SpriteKit/PotNode.swift`

The kawaii pot with eyes, mouth, blush, and expression states.

**Step 1: Create PotNode.swift**

```swift
//
//  PotNode.swift
//  personal_finance
//

import SpriteKit

/// Kawaii pot with expression system (eyes, mouth, blush).
/// Positioned at the bottom of the scene, the plant grows from inside it.
final class PotNode: SKNode {

    // MARK: - Expression State

    enum Expression {
        case expecting  // Round eyes + small mouth (default)
        case happy      // Curved smile eyes + smile arc
        case sleeping   // Closed eyes + "zzZ"
        case surprised  // Big eyes + O mouth
    }

    // MARK: - Properties

    private let sceneSize: CGSize
    private let potCenterX: CGFloat
    private let potBaseY: CGFloat
    private let potWidth: CGFloat = 90
    private let potHeight: CGFloat = 60

    // Expression nodes
    private var leftEye: SKShapeNode?
    private var rightEye: SKShapeNode?
    private var mouth: SKShapeNode?
    private var leftBlush: SKShapeNode?
    private var rightBlush: SKShapeNode?
    private var zzNode: SKLabelNode?

    private var currentExpression: Expression = .expecting

    // MARK: - Computed Properties

    /// Top of pot Y coordinate (where plants grow from)
    var potTopY: CGFloat {
        potBaseY + potHeight + 10
    }

    // MARK: - Initialization

    init(sceneSize: CGSize) {
        self.sceneSize = sceneSize
        self.potCenterX = sceneSize.width / 2
        self.potBaseY = sceneSize.height * 0.18
        super.init()
        self.zPosition = 1.5
        drawPot()
        drawFace()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Drawing

    private func drawPot() {
        // Rounded pot body — coral/cream color
        let bodyPath = CGMutablePath()
        let topHalf = potWidth / 2
        let bottomHalf = potWidth * 0.35
        let cornerRadius: CGFloat = 8

        // Draw rounded trapezoid
        bodyPath.move(to: CGPoint(x: potCenterX - topHalf + cornerRadius, y: potBaseY + potHeight))
        bodyPath.addLine(to: CGPoint(x: potCenterX + topHalf - cornerRadius, y: potBaseY + potHeight))
        bodyPath.addQuadCurve(
            to: CGPoint(x: potCenterX + topHalf, y: potBaseY + potHeight - cornerRadius),
            control: CGPoint(x: potCenterX + topHalf, y: potBaseY + potHeight)
        )
        bodyPath.addLine(to: CGPoint(x: potCenterX + bottomHalf, y: potBaseY + cornerRadius))
        bodyPath.addQuadCurve(
            to: CGPoint(x: potCenterX + bottomHalf - cornerRadius, y: potBaseY),
            control: CGPoint(x: potCenterX + bottomHalf, y: potBaseY)
        )
        bodyPath.addLine(to: CGPoint(x: potCenterX - bottomHalf + cornerRadius, y: potBaseY))
        bodyPath.addQuadCurve(
            to: CGPoint(x: potCenterX - bottomHalf, y: potBaseY + cornerRadius),
            control: CGPoint(x: potCenterX - bottomHalf, y: potBaseY)
        )
        bodyPath.addLine(to: CGPoint(x: potCenterX - topHalf, y: potBaseY + potHeight - cornerRadius))
        bodyPath.addQuadCurve(
            to: CGPoint(x: potCenterX - topHalf + cornerRadius, y: potBaseY + potHeight),
            control: CGPoint(x: potCenterX - topHalf, y: potBaseY + potHeight)
        )
        bodyPath.closeSubpath()

        let body = SKShapeNode(path: bodyPath)
        body.fillColor = SKColor(red: 1.0, green: 0.87, blue: 0.77, alpha: 1.0) // Peach cream
        body.strokeColor = SKColor(red: 0.9, green: 0.75, blue: 0.65, alpha: 1.0)
        body.lineWidth = 1.5
        addChild(body)

        // Pot rim — slightly wider, rounded
        let rimY = potBaseY + potHeight
        let rimHeight: CGFloat = 8
        let rimExtra: CGFloat = 4

        let rimPath = CGMutablePath()
        rimPath.addRoundedRect(
            in: CGRect(
                x: potCenterX - topHalf - rimExtra,
                y: rimY,
                width: (topHalf + rimExtra) * 2,
                height: rimHeight
            ),
            cornerWidth: 4,
            cornerHeight: 4
        )

        let rim = SKShapeNode(path: rimPath)
        rim.fillColor = SKColor(red: 0.95, green: 0.80, blue: 0.70, alpha: 1.0)
        rim.strokeColor = SKColor(red: 0.85, green: 0.70, blue: 0.60, alpha: 1.0)
        rim.lineWidth = 1.0
        addChild(rim)

        // Soil ellipse on top
        let soil = SKShapeNode(ellipseOf: CGSize(width: topHalf * 1.8, height: 10))
        soil.position = CGPoint(x: potCenterX, y: rimY + rimHeight - 1)
        soil.fillColor = SKColor(red: 0.45, green: 0.32, blue: 0.20, alpha: 1.0)
        soil.strokeColor = .clear
        soil.zPosition = 0.1
        addChild(soil)

        // Permanent blush circles
        let blushSize = CGSize(width: 14, height: 9)
        let faceY = potBaseY + potHeight * 0.55

        let leftB = SKShapeNode(ellipseOf: blushSize)
        leftB.fillColor = SKColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 0.4)
        leftB.strokeColor = .clear
        leftB.position = CGPoint(x: potCenterX - 22, y: faceY - 8)
        addChild(leftB)
        leftBlush = leftB

        let rightB = SKShapeNode(ellipseOf: blushSize)
        rightB.fillColor = SKColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 0.4)
        rightB.strokeColor = .clear
        rightB.position = CGPoint(x: potCenterX + 22, y: faceY - 8)
        addChild(rightB)
        rightBlush = rightB
    }

    private func drawFace() {
        setExpression(.expecting, animated: false)
    }

    // MARK: - Expression System

    func setExpression(_ expression: Expression, animated: Bool) {
        // Remove old face elements
        leftEye?.removeFromParent()
        rightEye?.removeFromParent()
        mouth?.removeFromParent()
        zzNode?.removeFromParent()
        zzNode = nil

        let faceY = potBaseY + potHeight * 0.55
        let eyeSpacing: CGFloat = 16

        switch expression {
        case .expecting:
            // Round eyes
            let le = SKShapeNode(circleOfRadius: 4)
            le.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            le.strokeColor = .clear
            le.position = CGPoint(x: potCenterX - eyeSpacing, y: faceY)
            addChild(le)
            leftEye = le

            let re = SKShapeNode(circleOfRadius: 4)
            re.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            re.strokeColor = .clear
            re.position = CGPoint(x: potCenterX + eyeSpacing, y: faceY)
            addChild(re)
            rightEye = re

            // Small round mouth
            let m = SKShapeNode(circleOfRadius: 2.5)
            m.fillColor = SKColor(red: 0.9, green: 0.5, blue: 0.5, alpha: 1.0)
            m.strokeColor = .clear
            m.position = CGPoint(x: potCenterX, y: faceY - 12)
            addChild(m)
            mouth = m

        case .happy:
            // Curved smile eyes (upside-down arcs)
            let le = createSmileEye(at: CGPoint(x: potCenterX - eyeSpacing, y: faceY))
            addChild(le)
            leftEye = le

            let re = createSmileEye(at: CGPoint(x: potCenterX + eyeSpacing, y: faceY))
            addChild(re)
            rightEye = re

            // Smile arc mouth
            let mouthPath = CGMutablePath()
            mouthPath.move(to: CGPoint(x: -8, y: 0))
            mouthPath.addQuadCurve(to: CGPoint(x: 8, y: 0), control: CGPoint(x: 0, y: -6))
            let m = SKShapeNode(path: mouthPath)
            m.strokeColor = SKColor(red: 0.9, green: 0.5, blue: 0.5, alpha: 1.0)
            m.lineWidth = 2.0
            m.lineCap = .round
            m.position = CGPoint(x: potCenterX, y: faceY - 12)
            addChild(m)
            mouth = m

        case .sleeping:
            // Closed eyes (horizontal lines)
            let le = createClosedEye(at: CGPoint(x: potCenterX - eyeSpacing, y: faceY))
            addChild(le)
            leftEye = le

            let re = createClosedEye(at: CGPoint(x: potCenterX + eyeSpacing, y: faceY))
            addChild(re)
            rightEye = re

            // Small closed mouth
            let mouthPath = CGMutablePath()
            mouthPath.move(to: CGPoint(x: -4, y: 0))
            mouthPath.addLine(to: CGPoint(x: 4, y: 0))
            let m = SKShapeNode(path: mouthPath)
            m.strokeColor = SKColor(red: 0.9, green: 0.5, blue: 0.5, alpha: 0.6)
            m.lineWidth = 1.5
            m.lineCap = .round
            m.position = CGPoint(x: potCenterX, y: faceY - 12)
            addChild(m)
            mouth = m

            // "zzZ" label
            let zz = SKLabelNode(text: "zzZ")
            zz.fontName = "AvenirNext-Bold"
            zz.fontSize = 12
            zz.fontColor = SKColor(red: 0.6, green: 0.6, blue: 0.8, alpha: 0.7)
            zz.position = CGPoint(x: potCenterX + 35, y: faceY + 15)
            addChild(zz)
            zzNode = zz

            // Float animation for zzZ
            let floatUp = SKAction.moveBy(x: 0, y: 5, duration: 1.5)
            let floatDown = SKAction.moveBy(x: 0, y: -5, duration: 1.5)
            zz.run(.repeatForever(.sequence([floatUp, floatDown])))

        case .surprised:
            // Big round eyes
            let le = SKShapeNode(circleOfRadius: 6)
            le.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            le.strokeColor = .clear
            le.position = CGPoint(x: potCenterX - eyeSpacing, y: faceY)
            addChild(le)
            leftEye = le

            // White highlight in eye
            let lh = SKShapeNode(circleOfRadius: 2)
            lh.fillColor = .white
            lh.strokeColor = .clear
            lh.position = CGPoint(x: 1.5, y: 1.5)
            le.addChild(lh)

            let re = SKShapeNode(circleOfRadius: 6)
            re.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            re.strokeColor = .clear
            re.position = CGPoint(x: potCenterX + eyeSpacing, y: faceY)
            addChild(re)
            rightEye = re

            let rh = SKShapeNode(circleOfRadius: 2)
            rh.fillColor = .white
            rh.strokeColor = .clear
            rh.position = CGPoint(x: 1.5, y: 1.5)
            re.addChild(rh)

            // O-shaped mouth
            let m = SKShapeNode(ellipseOf: CGSize(width: 8, height: 10))
            m.fillColor = SKColor(red: 0.9, green: 0.5, blue: 0.5, alpha: 1.0)
            m.strokeColor = SKColor(red: 0.8, green: 0.4, blue: 0.4, alpha: 1.0)
            m.lineWidth = 1.0
            m.position = CGPoint(x: potCenterX, y: faceY - 13)
            addChild(m)
            mouth = m
        }

        currentExpression = expression

        if animated {
            // Quick scale bounce
            let scaleUp = SKAction.scale(to: 1.05, duration: 0.1)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
            run(.sequence([scaleUp, scaleDown]))
        }
    }

    // MARK: - Blink Animation

    func playBlink() {
        guard currentExpression == .expecting else { return }
        // Temporarily replace eyes with closed, then revert
        let savedExpr = currentExpression
        setExpression(.sleeping, animated: false)
        zzNode?.removeFromParent()
        zzNode = nil

        run(.sequence([
            .wait(forDuration: 0.15),
            .run { [weak self] in
                self?.setExpression(savedExpr, animated: false)
            }
        ]))
    }

    // MARK: - Interaction Animations

    func playTapReaction() {
        // Wobble left-right
        let rotateLeft = SKAction.rotate(byAngle: CGFloat.pi / 30, duration: 0.08)
        let rotateRight = SKAction.rotate(byAngle: -CGFloat.pi / 15, duration: 0.16)
        let rotateBack = SKAction.rotate(byAngle: CGFloat.pi / 30, duration: 0.08)
        run(.sequence([rotateLeft, rotateRight, rotateBack]))

        setExpression(.happy, animated: false)

        // Revert to expecting after 1.5s
        run(.sequence([
            .wait(forDuration: 1.5),
            .run { [weak self] in
                self?.setExpression(.expecting, animated: false)
            }
        ]))
    }

    func playLongPressReaction() {
        // Deepen blush
        leftBlush?.run(.fadeAlpha(to: 0.7, duration: 0.3))
        rightBlush?.run(.fadeAlpha(to: 0.7, duration: 0.3))

        setExpression(.happy, animated: true)

        // Revert after 2s
        run(.sequence([
            .wait(forDuration: 2.0),
            .run { [weak self] in
                self?.leftBlush?.run(.fadeAlpha(to: 0.4, duration: 0.3))
                self?.rightBlush?.run(.fadeAlpha(to: 0.4, duration: 0.3))
                self?.setExpression(.expecting, animated: false)
            }
        ]))
    }

    func playJumpReaction() {
        let jumpUp = SKAction.moveBy(x: 0, y: 15, duration: 0.15)
        jumpUp.timingMode = .easeOut
        let jumpDown = SKAction.moveBy(x: 0, y: -15, duration: 0.2)
        jumpDown.timingMode = .easeIn
        run(.sequence([jumpUp, jumpDown]))

        setExpression(.surprised, animated: false)
        run(.sequence([
            .wait(forDuration: 1.0),
            .run { [weak self] in self?.setExpression(.happy, animated: false) },
            .wait(forDuration: 1.0),
            .run { [weak self] in self?.setExpression(.expecting, animated: false) }
        ]))
    }

    // MARK: - Helpers

    private func createSmileEye(at position: CGPoint) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -4, y: 0))
        path.addQuadCurve(to: CGPoint(x: 4, y: 0), control: CGPoint(x: 0, y: 4))
        let eye = SKShapeNode(path: path)
        eye.strokeColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        eye.lineWidth = 2.0
        eye.lineCap = .round
        eye.position = position
        return eye
    }

    private func createClosedEye(at position: CGPoint) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -4, y: 0))
        path.addLine(to: CGPoint(x: 4, y: 0))
        let eye = SKShapeNode(path: path)
        eye.strokeColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        eye.lineWidth = 2.0
        eye.lineCap = .round
        eye.position = position
        return eye
    }
}
```

**Step 2: Build to verify compilation**

Run:
```bash
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build
```
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add personal_finance/SpriteKit/PotNode.swift
git commit -m "feat: add PotNode with kawaii expression system"
```

---

### Task 3: Redesign BackgroundNode — Dreamy Gradients + Decorations

**Files:**
- Modify: `personal_finance/SpriteKit/BackgroundNode.swift` (replace entire file)

Change the gradient colors to dreamy pastels and add floating cloud decorations.

**Step 1: Rewrite BackgroundNode.swift**

Replace `gradientColors(for:)` with the new dreamy palette from the design doc:

| Stage | Top | Bottom |
|-------|-----|--------|
| 0 | `#FFE4E1` (Misty Rose) | `#FFF8DC` (Cornsilk) |
| 1 | `#E8D5F5` (Lavender) | `#E8F5E9` (Honeydew) |
| 2 | `#E0F0FF` (Alice Blue) | `#C8E6C9` (Light Green) |
| 3 | `#F3E5F5` (Magnolia) | `#FFF9C4` (Lemon Chiffon) |
| 4 | `#FFE0E6` (Lavender Blush) | `#FFE0B2` (Moccasin) |

Also add:
- 2-3 floating cloud decorations (composed of overlapping circles using `SKShapeNode`)
- Clouds drift slowly left/right with `SKAction.sequence` of moveTo + reverse

Full replacement code for `gradientColors(for:)`:

```swift
private func gradientColors(for stage: Int) -> (top: UIColor, bottom: UIColor) {
    switch stage {
    case 0:
        return (
            top: UIColor(red: 1.0, green: 0.894, blue: 0.882, alpha: 1.0),     // #FFE4E1
            bottom: UIColor(red: 1.0, green: 0.973, blue: 0.863, alpha: 1.0)   // #FFF8DC
        )
    case 1:
        return (
            top: UIColor(red: 0.91, green: 0.835, blue: 0.96, alpha: 1.0),     // #E8D5F5
            bottom: UIColor(red: 0.91, green: 0.96, blue: 0.914, alpha: 1.0)   // #E8F5E9
        )
    case 2:
        return (
            top: UIColor(red: 0.878, green: 0.941, blue: 1.0, alpha: 1.0),     // #E0F0FF
            bottom: UIColor(red: 0.784, green: 0.902, blue: 0.788, alpha: 1.0) // #C8E6C9
        )
    case 3:
        return (
            top: UIColor(red: 0.953, green: 0.898, blue: 0.961, alpha: 1.0),   // #F3E5F5
            bottom: UIColor(red: 1.0, green: 0.976, blue: 0.769, alpha: 1.0)   // #FFF9C4
        )
    default:
        return (
            top: UIColor(red: 1.0, green: 0.878, blue: 0.902, alpha: 1.0),     // #FFE0E6
            bottom: UIColor(red: 1.0, green: 0.878, blue: 0.698, alpha: 1.0)   // #FFE0B2
        )
    }
}
```

Add a new method `setupClouds()` called from `init`:

```swift
private func setupClouds() {
    let cloud1 = createCloud(radius: 12)
    cloud1.position = CGPoint(x: sceneSize.width * 0.2, y: sceneSize.height * 0.82)
    cloud1.alpha = 0.6
    addChild(cloud1)
    animateCloudDrift(cloud1, range: 30, duration: 8)

    let cloud2 = createCloud(radius: 10)
    cloud2.position = CGPoint(x: sceneSize.width * 0.75, y: sceneSize.height * 0.75)
    cloud2.alpha = 0.5
    addChild(cloud2)
    animateCloudDrift(cloud2, range: 25, duration: 10)

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
```

Add `setupClouds()` call at the end of `init(sceneSize:)`.

**Step 2: Build to verify**

Run build command. Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add personal_finance/SpriteKit/BackgroundNode.swift
git commit -m "feat: redesign BackgroundNode with dreamy pastel gradients and floating clouds"
```

---

### Task 4: Redesign GroundNode — Cute Grass Hill

**Files:**
- Modify: `personal_finance/SpriteKit/GroundNode.swift` (replace entire file)

Replace brown earth mound + terracotta pot with a cute rounded green grass hill with small flower decorations. The pot is now handled by PotNode.

**Step 1: Rewrite GroundNode.swift**

Remove `setupPot()` entirely (pot is now PotNode). Change `setupGround()` to draw:
1. A rounded green grass hill (softer green color)
2. Small decorative flowers (3-4 tiny colorful circles scattered on the hill)

```swift
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

        // Small decorative flowers on the hill
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

        // 4 tiny petals
        let petalRadius: CGFloat = 3
        let offsets: [(CGFloat, CGFloat)] = [(0, petalRadius), (0, -petalRadius), (petalRadius, 0), (-petalRadius, 0)]
        for (dx, dy) in offsets {
            let petal = SKShapeNode(circleOfRadius: petalRadius)
            petal.fillColor = color
            petal.strokeColor = .clear
            petal.position = CGPoint(x: dx, y: dy)
            node.addChild(petal)
        }

        // Center dot
        let center = SKShapeNode(circleOfRadius: 2)
        center.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1.0)
        center.strokeColor = .clear
        center.zPosition = 0.1
        node.addChild(center)

        return node
    }
}
```

**Step 2: Build to verify**

Run build command. Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add personal_finance/SpriteKit/GroundNode.swift
git commit -m "feat: redesign GroundNode as cute grass hill with flower decorations"
```

---

### Task 5: Redesign PlantNode — Kawaii Cartoon Plant

**Files:**
- Modify: `personal_finance/SpriteKit/PlantNode.swift` (replace entire file)

Redraw all 5 stages with kawaii cartoon style. Rounder leaves, cuter proportions. The plant now grows from `PotNode.potTopY` instead of calculating its own baseY.

**Step 1: Rewrite PlantNode with kawaii style**

Key changes:
- `baseY` is now passed in from `PotNode.potTopY` (or calculated as `sceneSize.height * 0.18 + 60 + 10 + 8 - 1` = roughly same)
- Rounder, more cartoonish leaves using larger ellipses
- Stage 0: Cute seed with a tiny sparkle
- Stage 1-2: Rounder, bigger leaves
- Stage 3: Dancing bushy plant
- Stage 4: Big kawaii flower with heart particles

The structure stays the same (morphTo, buildStage, startIdleAnimation, playGrowthSpurt). Only the drawing methods change proportions and colors to be more cartoonish.

Key visual changes per stage:
- Seed: Bigger (28x20), lighter brown, with a tiny star sparkle
- Sprout: Stem color becomes brighter green, leaves are rounder (use ellipse instead of pointed shape)
- Seedling: Leaves are wider and more oval
- Bushy: Softer green tones, more rounded shapes
- Flowering: Bigger flower with 6 petals, pink with gradient feel

Update `createLeaf` to use rounder ellipses instead of pointed shapes:
```swift
private func createLeaf(at position: CGPoint, size: CGSize, angle: CGFloat, color: SKColor) -> SKShapeNode {
    // Rounder kawaii leaf — simple ellipse
    let leaf = SKShapeNode(ellipseOf: size)
    leaf.fillColor = color
    leaf.strokeColor = color.darker()
    leaf.lineWidth = 1.0
    leaf.position = position
    leaf.zRotation = angle
    return leaf
}
```

Keep the `SKColor.darker()` extension as-is.

**Step 2: Build to verify**

Run build command. Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add personal_finance/SpriteKit/PlantNode.swift
git commit -m "feat: redesign PlantNode with kawaii cartoon style"
```

---

### Task 6: Upgrade ParticleEffects — Hearts, Stars, Butterflies, Confetti

**Files:**
- Modify: `personal_finance/SpriteKit/ParticleEffects.swift`

Add new kawaii particle types while keeping existing ones (with updated colors).

**Step 1: Add new particle methods**

Add these new static methods to the `ParticleEffects` enum:

```swift
// MARK: - Hearts

/// Small floating heart particles
static func hearts() -> SKEmitterNode {
    let emitter = SKEmitterNode()

    // Heart texture: draw a small heart shape
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
    emitter.emissionAngle = .pi / 2  // upward
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

/// Colorful star-like sparkles for growth celebration
static func stars() -> SKEmitterNode {
    let emitter = SKEmitterNode()

    // Star texture: 4-pointed star
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

    emitter.particleColor = UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0) // Gold
    emitter.particleColorBlendFactor = 1.0
    emitter.particleBlendMode = .add

    return emitter
}

// MARK: - Confetti

/// Rainbow confetti burst for stage-up
static func confetti() -> SKEmitterNode {
    let emitter = SKEmitterNode()

    // Small rectangle confetti
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

    // Rainbow colors via color sequence
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

/// Dreamy multi-color ambient particles (replaces green-only ambientGlow)
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

    // Soft pastel pink/purple/green mix
    emitter.particleColor = UIColor(red: 1.0, green: 0.8, blue: 0.9, alpha: 1.0)
    emitter.particleColorBlendFactor = 1.0
    emitter.particleColorRedRange = 0.3
    emitter.particleColorGreenRange = 0.2
    emitter.particleColorBlueRange = 0.3
    emitter.particleBlendMode = .add

    return emitter
}
```

Also update existing `waterDrops()` color to be brighter blue, and `stageUpBurst()` to use the new `confetti()` pattern.

**Step 2: Build to verify**

Run build command. Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add personal_finance/SpriteKit/ParticleEffects.swift
git commit -m "feat: add kawaii particles — hearts, stars, confetti, dreamy ambient"
```

---

### Task 7: Redesign SproutScene — Touch, Expressions, Speech Bubbles, Audio

**Files:**
- Modify: `personal_finance/SpriteKit/SproutScene.swift` (major rewrite)

This is the main orchestrator. Add:
1. PotNode integration
2. Touch handling (tap, multi-tap, long press)
3. Speech bubble system
4. AudioService integration
5. Blink timer
6. Updated animation sequences

**Step 1: Rewrite SproutScene.swift**

Key changes:

```swift
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
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Cancel any pending long press
        longPressTimer?.invalidate()

        // Start long press timer
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.handleLongPress(at: location)
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
            // Single/double tap
            potNode?.playTapReaction()

            // Spawn 1-2 hearts near tap
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

            // Show random speech bubble
            showSpeechBubble()
        }
    }

    private func handleLongPress(at location: CGPoint) {
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

        // Background rounded rect
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

        // Animate: fade in, float up, fade out
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
        // Phase 1: Water drops + sound
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

        // Phase 2: Happy expression + growth spurt + grow sound
        run(.sequence([
            .wait(forDuration: 0.5),
            .run { [weak self] in
                self?.potNode?.setExpression(.happy, animated: true)
                self?.plantNode?.playGrowthSpurt()
                AudioService.shared.play(.grow)
            }
        ]))

        // Phase 3: Stars + hearts
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

        // Phase 4: Floating "+N" text
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

        // Revert expression + completion
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

        // Flash
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

        // Surprised expression
        potNode?.setExpression(.surprised, animated: true)

        // Confetti burst
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

        // "Level Up!" text
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

        // Revert expression + completion
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
```

**Step 2: Build to verify**

Run build command. Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add personal_finance/SpriteKit/SproutScene.swift
git commit -m "feat: integrate touch interactions, expressions, speech bubbles, and audio into SproutScene"
```

---

### Task 8: Redesign SproutTabView — Kawaii UI

**Files:**
- Modify: `personal_finance/Views/SproutTabView.swift`

Update the UI to match the kawaii aesthetic:
1. Larger SpriteView area with bigger corner radius
2. Level label (Lv 0-4)
3. Capsule-shaped progress bar
4. Cute status messages
5. Sleeping expression when already watered
6. Dreamy background color

**Step 1: Update SproutTabView**

Key changes:

1. `plantVisual`: Change frame to fill width, corner radius to 32, add name + level label
2. `progressSection`: Use `Capsule()` for progress bar clip shape
3. `todayStatusCard`: Update text to kawaii style, trigger sleeping expression
4. Navigation title: "我的小豆芽"
5. Background: Change from `.systemGroupedBackground` to a subtle gradient

Replace `plantVisual`:
```swift
private var plantVisual: some View {
    VStack(spacing: 12) {
        if let scene = sproutScene {
            SpriteView(scene: scene, options: [.allowsTransparency])
                .frame(maxWidth: .infinity)
                .frame(height: 380)
                .clipShape(RoundedRectangle(cornerRadius: 32))
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .frame(height: 380)
        }

        HStack(spacing: 8) {
            Text("我的小豆芽")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.onBackground)

            Text("Lv \(plant?.currentStage ?? 0)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(stageColor))
        }
    }
}
```

Update `todayStatusCard` text:
- Watered: "今天已澆水囉~" / "豆芽正在開心成長中"
- Not watered: "今日尚未記帳" / "去記帳澆灌你的小豆芽吧！"

Add `.onChange(of: hasWateredToday)` to trigger sleeping expression:
```swift
.onChange(of: hasWateredToday) { _, watered in
    if watered {
        sproutScene?.setExpression(.sleeping)
    }
}
```

And in `setupScene()`, after configure, check if already watered today:
```swift
if hasWateredToday {
    sproutScene?.setExpression(.sleeping)
}
```

**Step 2: Build to verify**

Run build command. Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add personal_finance/Views/SproutTabView.swift
git commit -m "feat: redesign SproutTabView with kawaii UI and level labels"
```

---

### Task 9: Add Audio Settings to SettingsView

**Files:**
- Modify: `personal_finance/Views/SettingsView.swift`

Add a new "音效" section with sound effects toggle and music toggle.

**Step 1: Add audio settings section**

Add after the "外觀" section in SettingsView:

```swift
// Add these @AppStorage properties
@AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
@AppStorage("backgroundMusicEnabled") private var backgroundMusicEnabled = true

// Add this Section in the List/Form body
Section("音效") {
    Toggle(isOn: $soundEffectsEnabled) {
        Label("音效", systemImage: "speaker.wave.2")
    }
    Toggle(isOn: $backgroundMusicEnabled) {
        Label("背景音樂", systemImage: "music.note")
    }
}
```

**Step 2: Build to verify**

Run build command. Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add personal_finance/Views/SettingsView.swift
git commit -m "feat: add audio settings toggles to SettingsView"
```

---

### Task 10: Update AddTransactionView — Mini Scene Audio

**Files:**
- Modify: `personal_finance/Views/AddTransactionView.swift`

Add audio playback to the mini sprout scene that appears after recording a transaction.

**Step 1: Find and update the growth popup section**

After `mini.playWaterAnimation(pointsEarned:)` is called, the AudioService is already triggered inside SproutScene. No additional changes needed for audio since SproutScene.playWaterAnimation now calls AudioService internally.

However, if the mini scene creates its own SproutScene instance, verify it will also trigger audio. If the mini scene uses a separate SproutScene instance, the AudioService.shared singleton will handle audio correctly.

If harvest celebration also needs audio:
```swift
// In performHarvest() or equivalent, add:
AudioService.shared.play(.harvest)
```

**Step 2: Build to verify**

Run build command. Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add personal_finance/Views/AddTransactionView.swift
git commit -m "feat: integrate audio into transaction growth popup"
```

---

### Task 11: Final Build Verification & Visual Testing

**Step 1: Full clean build**

```bash
xcodebuild clean build -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06'
```
Expected: BUILD SUCCEEDED

**Step 2: Run existing unit tests**

```bash
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' \
  -only-testing:personal_financeTests
```
Expected: All tests pass (growth service tests should be unaffected since we didn't change models or growth logic)

**Step 3: Visual verification checklist**

Launch in simulator and manually verify:
- [ ] Sprout tab shows kawaii pot with face
- [ ] Background has dreamy pastel gradient
- [ ] Floating clouds are visible
- [ ] Small flowers on grass hill
- [ ] Tapping pot triggers wobble + speech bubble + sound
- [ ] Triple-tap triggers jump + stars
- [ ] Pot blinks every ~4 seconds
- [ ] Recording a transaction triggers water animation + sound
- [ ] Stage progression shows confetti + level-up text
- [ ] Settings page has audio toggles
- [ ] Disabling sound effects mutes all sounds

**Step 4: Final commit**

```bash
git add -A
git commit -m "chore: final build verification — kawaii sprout redesign complete"
```

---

## Execution Order & Dependencies

```
Task 1 (AudioService)     ─── independent
Task 2 (PotNode)          ─── independent
Task 3 (BackgroundNode)   ─── independent
Task 4 (GroundNode)       ─── independent
Task 5 (PlantNode)        ─── independent
Task 6 (ParticleEffects)  ─── independent
                          ↓
Task 7 (SproutScene)      ─── depends on Tasks 1-6
                          ↓
Task 8 (SproutTabView)    ─── depends on Task 7
Task 9 (SettingsView)     ─── depends on Task 1
Task 10 (AddTransaction)  ─── depends on Task 7
                          ↓
Task 11 (Final verify)    ─── depends on all
```

Tasks 1-6 can be executed in parallel. Tasks 8-10 can be executed in parallel after Task 7.
