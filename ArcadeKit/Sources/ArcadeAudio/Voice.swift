import Foundation

public struct Tone: Hashable, Sendable {
    public var pitch: Pitch
    public var waveform: Waveform
    public var envelope: Envelope
    public var duration: Double
    public var gain: Double
    public var bend: Double

    public init(
        pitch: Pitch, waveform: Waveform = .square, envelope: Envelope = .pluck,
        duration: Double = 0.12, gain: Double = 0.5, bend: Double = 0
    ) {
        self.pitch = pitch
        self.waveform = waveform
        self.envelope = envelope
        self.duration = duration
        self.gain = gain
        self.bend = bend
    }

    public var totalDuration: Double { duration + envelope.tail }
}

public enum Synthesizer {
    public static let sampleRate: Double = 44_100

    public static func render(_ tone: Tone, sampleRate: Double = Synthesizer.sampleRate) -> [Float] {
        let total = tone.totalDuration
        let count = max(Int(total * sampleRate), 1)
        guard !tone.pitch.isRest else { return [Float](repeating: 0, count: count) }

        var samples = [Float](repeating: 0, count: count)
        var phase = 0.0
        var seed: UInt64 = 0x1234_5678_9ABC_DEF0
        let base = tone.pitch.frequency

        for index in 0..<count {
            let time = Double(index) / sampleRate
            let progress = total <= 0 ? 0 : time / total
            let frequency = max(base * (1 + tone.bend * progress), 1)
            phase += frequency / sampleRate
            let value = tone.waveform.sample(phase: phase, seed: &seed)
            let amplitude = tone.envelope.amplitude(at: time, duration: tone.duration)
            samples[index] = Float(value * amplitude * tone.gain)
        }
        return samples
    }

    public static func mix(_ tracks: [[Float]]) -> [Float] {
        let length = tracks.map(\.count).max() ?? 0
        guard length > 0 else { return [] }
        var output = [Float](repeating: 0, count: length)
        for track in tracks {
            for index in 0..<track.count {
                output[index] += track[index]
            }
        }
        var peak: Float = 0
        for value in output {
            peak = max(peak, abs(value))
        }
        if peak > 1 {
            let scale = 1 / peak
            for index in 0..<output.count {
                output[index] *= scale
            }
        }
        return output
    }

    public static func sequence(_ tones: [Tone], sampleRate: Double = Synthesizer.sampleRate)
        -> [Float]
    {
        var offsets: [(Int, [Float])] = []
        var cursor = 0.0
        for tone in tones {
            offsets.append((Int(cursor * sampleRate), render(tone, sampleRate: sampleRate)))
            cursor += tone.duration
        }
        let length = offsets.map { $0.0 + $0.1.count }.max() ?? 0
        guard length > 0 else { return [] }
        var output = [Float](repeating: 0, count: length)
        for (start, samples) in offsets {
            for index in 0..<samples.count where start + index < length {
                output[start + index] += samples[index]
            }
        }
        return output
    }
}
