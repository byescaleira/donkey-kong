import AVFoundation
import Foundation

@MainActor
public final class AudioEngine {
    public private(set) var isRunning = false
    public var musicVolume: Double = 0.5 {
        didSet { musicNode.volume = Float(musicVolume.clamped01) }
    }
    public var effectsVolume: Double = 0.8 {
        didSet {
            for node in effectNodes { node.volume = Float(effectsVolume.clamped01) }
        }
    }

    private let engine = AVAudioEngine()
    private let musicNode = AVAudioPlayerNode()
    private var effectNodes: [AVAudioPlayerNode] = []
    private var nextEffectNode = 0
    private var effectBuffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var musicBuffer: AVAudioPCMBuffer?
    private let format: AVAudioFormat

    public init?(effectVoices: Int = 6) {
        guard
            let format = AVAudioFormat(
                commonFormat: .pcmFormatFloat32, sampleRate: Synthesizer.sampleRate, channels: 1,
                interleaved: false)
        else { return nil }
        self.format = format

        engine.attach(musicNode)
        engine.connect(musicNode, to: engine.mainMixerNode, format: format)
        for _ in 0..<max(effectVoices, 1) {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            effectNodes.append(node)
        }
        musicNode.volume = Float(musicVolume)
        for node in effectNodes { node.volume = Float(effectsVolume) }
    }

    public func start() {
        guard !isRunning else { return }
        configureSession()
        do {
            try engine.start()
            isRunning = true
            for node in effectNodes { node.play() }
        } catch {
            isRunning = false
        }
    }

    public func stop() {
        guard isRunning else { return }
        musicNode.stop()
        for node in effectNodes { node.stop() }
        engine.stop()
        isRunning = false
    }

    public func prepare() {
        for effect in SoundEffect.allCases {
            effectBuffers[effect] = buffer(from: effect.render())
        }
    }

    public func play(_ effect: SoundEffect) {
        guard isRunning, effectsVolume > 0 else { return }
        let buffer: AVAudioPCMBuffer?
        if let cached = effectBuffers[effect] {
            buffer = cached
        } else {
            buffer = self.buffer(from: effect.render())
            effectBuffers[effect] = buffer
        }
        guard let buffer, !effectNodes.isEmpty else { return }
        let node = effectNodes[nextEffectNode % effectNodes.count]
        nextEffectNode += 1
        if !node.isPlaying { node.play() }
        node.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }

    public func playMusic(_ score: MusicScore) {
        guard isRunning else { return }
        guard let buffer = buffer(from: score.render()) else { return }
        musicBuffer = buffer
        musicNode.stop()
        musicNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        musicNode.play()
    }

    public func stopMusic() {
        musicNode.stop()
        musicBuffer = nil
    }

    private func buffer(from samples: [Float]) -> AVAudioPCMBuffer? {
        guard !samples.isEmpty,
            let buffer = AVAudioPCMBuffer(
                pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))
        else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        guard let channel = buffer.floatChannelData?[0] else { return nil }
        samples.withUnsafeBufferPointer { source in
            guard let base = source.baseAddress else { return }
            channel.update(from: base, count: samples.count)
        }
        return buffer
    }

    private func configureSession() {
        #if os(iOS) || os(tvOS)
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try? session.setActive(true)
        #endif
    }
}

extension Double {
    fileprivate var clamped01: Double { min(max(self, 0), 1) }
}
