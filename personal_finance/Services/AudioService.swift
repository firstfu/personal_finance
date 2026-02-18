// ============================================================================
// MARK: - AudioService.swift
// 模組：Services
//
// 功能說明：
//   程式化音效合成引擎，使用 AVAudioEngine 即時產生 PCM 音訊。
//   不依賴任何音訊檔案，所有音效皆透過波形函數合成。
//
// 音效清單：
//   - waterDrop: 水滴聲（正弦波 800Hz→200Hz 下降）
//   - grow:      成長聲（三角波 300Hz→600Hz 上升）
//   - stageUp:   階段提升（Do-Mi-Sol 琶音）
//   - harvest:   收成慶祝（C5-E5-G5-C6 琶音）
//   - tap:       點擊回饋（400Hz 短促正弦波）
//   - blink:     眨眼音效（短促唧聲）
// ============================================================================

import AVFoundation
import SwiftUI

// MARK: - SoundEffect

enum SoundEffect: CaseIterable {
    case waterDrop
    case grow
    case stageUp
    case harvest
    case tap
    case blink

    /// 音效持續時間（秒）
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

    /// 波形產生函數，接收時間 t（秒）回傳振幅 -1...1
    var waveform: (Double) -> Double {
        switch self {
        case .waterDrop:
            // 正弦波，頻率從 800Hz 線性下降至 200Hz
            return { t in
                let freq = 800.0 - (600.0 * t / 0.3)
                return sin(2.0 * .pi * freq * t)
            }

        case .grow:
            // 三角波，頻率從 300Hz 上升至 600Hz
            return { t in
                let freq = 300.0 + (300.0 * t / 0.4)
                let phase = freq * t
                let fractional = phase - floor(phase)
                return 4.0 * abs(fractional - 0.5) - 1.0
            }

        case .stageUp:
            // Do-Mi-Sol (C5=523.25, E5=659.25, G5=783.99) 琶音
            return { t in
                let noteFreq: Double
                if t < 0.2 {
                    noteFreq = 523.25 // C5
                } else if t < 0.4 {
                    noteFreq = 659.25 // E5
                } else {
                    noteFreq = 783.99 // G5
                }
                return sin(2.0 * .pi * noteFreq * t)
            }

        case .harvest:
            // C5-E5-G5-C6 四音琶音
            return { t in
                let noteFreq: Double
                if t < 0.2 {
                    noteFreq = 523.25 // C5
                } else if t < 0.4 {
                    noteFreq = 659.25 // E5
                } else if t < 0.6 {
                    noteFreq = 783.99 // G5
                } else {
                    noteFreq = 1046.50 // C6
                }
                return sin(2.0 * .pi * noteFreq * t)
            }

        case .tap:
            // 400Hz 短促正弦波
            return { t in
                sin(2.0 * .pi * 400.0 * t)
            }

        case .blink:
            // 短促唧聲：sin(1200t) * sin(80t)
            return { t in
                sin(2.0 * .pi * 1200.0 * t) * sin(2.0 * .pi * 80.0 * t)
            }
        }
    }

    /// 振幅包絡函數，接收正規化進度 0...1 回傳增益 0...1
    var envelope: (Double) -> Double {
        switch self {
        case .waterDrop:
            // 快速起音，指數衰減
            return { progress in
                let attack = min(progress / 0.05, 1.0)
                let decay = exp(-4.0 * progress)
                return attack * decay
            }

        case .grow:
            // 緩慢起音，持續，尾端衰減
            return { progress in
                let attack = min(progress / 0.1, 1.0)
                let release = progress > 0.7 ? 1.0 - ((progress - 0.7) / 0.3) : 1.0
                return attack * release
            }

        case .stageUp:
            // 每個音符有獨立的起音與衰減
            return { progress in
                let noteProgress = (progress * 3.0).truncatingRemainder(dividingBy: 1.0)
                let attack = min(noteProgress / 0.05, 1.0)
                let decay = max(1.0 - noteProgress * 0.3, 0.4)
                return attack * decay
            }

        case .harvest:
            // 每個音符有獨立的起音，整體漸強
            return { progress in
                let noteProgress = (progress * 4.0).truncatingRemainder(dividingBy: 1.0)
                let attack = min(noteProgress / 0.05, 1.0)
                let crescendo = 0.6 + 0.4 * progress
                let release = progress > 0.9 ? 1.0 - ((progress - 0.9) / 0.1) : 1.0
                return attack * crescendo * release
            }

        case .tap:
            // 極快起音，快速衰減
            return { progress in
                let attack = min(progress / 0.02, 1.0)
                let decay = 1.0 - progress
                return attack * decay
            }

        case .blink:
            // 瞬間起音，線性衰減
            return { progress in
                1.0 - progress
            }
        }
    }
}

// MARK: - AudioService

final class AudioService {
    static let shared = AudioService()

    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled: Bool = true

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44100.0
    private let masterVolume: Float = 0.3

    private init() {
        setupEngine()
    }

    // MARK: - Engine Setup

    private func setupEngine() {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!

        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = masterVolume

        do {
            try engine.start()
        } catch {
            print("[AudioService] Engine start failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Play

    /// 播放指定音效
    func play(_ effect: SoundEffect) {
        guard soundEffectsEnabled else { return }

        // 確保引擎運行中
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("[AudioService] Engine restart failed: \(error.localizedDescription)")
                return
            }
        }

        guard let buffer = generateBuffer(for: effect) else { return }

        playerNode.scheduleBuffer(buffer, completionHandler: nil)

        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    // MARK: - Buffer Generation

    /// 產生指定音效的 PCM 音訊緩衝
    private func generateBuffer(for effect: SoundEffect) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!

        let frameCount = AVAudioFrameCount(effect.duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData?[0] else {
            return nil
        }

        let waveform = effect.waveform
        let envelope = effect.envelope
        let duration = effect.duration

        for i in 0 ..< Int(frameCount) {
            let t = Double(i) / sampleRate
            let progress = t / duration
            let sample = waveform(t) * envelope(progress)
            channelData[i] = Float(sample)
        }

        return buffer
    }
}
