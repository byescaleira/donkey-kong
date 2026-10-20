import Foundation

public enum Waveform: String, Sendable, CaseIterable {
    case square
    case pulse
    case triangle
    case sawtooth
    case noise

    public func sample(phase: Double, seed: inout UInt64) -> Double {
        let wrapped = phase - phase.rounded(.down)
        switch self {
        case .square:
            return wrapped < 0.5 ? 1 : -1
        case .pulse:
            return wrapped < 0.25 ? 1 : -1
        case .triangle:
            return wrapped < 0.5 ? (wrapped * 4 - 1) : (3 - wrapped * 4)
        case .sawtooth:
            return wrapped * 2 - 1
        case .noise:
            seed ^= seed << 13
            seed ^= seed >> 7
            seed ^= seed << 17
            return Double(seed % 2000) / 1000 - 1
        }
    }
}

public struct Envelope: Hashable, Sendable {
    public var attack: Double
    public var decay: Double
    public var sustain: Double
    public var release: Double

    public init(attack: Double, decay: Double, sustain: Double, release: Double) {
        self.attack = attack
        self.decay = decay
        self.sustain = sustain
        self.release = release
    }

    public static let pluck = Envelope(attack: 0.004, decay: 0.07, sustain: 0.45, release: 0.08)
    public static let blip = Envelope(attack: 0.001, decay: 0.03, sustain: 0.1, release: 0.04)
    public static let pad = Envelope(attack: 0.02, decay: 0.12, sustain: 0.7, release: 0.18)

    public func amplitude(at time: Double, duration: Double) -> Double {
        guard time >= 0 else { return 0 }
        let held = max(duration, 0.0001)
        if time < attack {
            return attack <= 0 ? 1 : time / attack
        }
        if time < attack + decay {
            let progress = decay <= 0 ? 1 : (time - attack) / decay
            return 1 - progress * (1 - sustain)
        }
        if time < held {
            return sustain
        }
        let releasing = time - held
        guard releasing < release else { return 0 }
        return release <= 0 ? 0 : sustain * (1 - releasing / release)
    }

    public var tail: Double { release }
}

public struct Pitch: Hashable, Sendable {
    public let midi: Int

    public init(midi: Int) {
        self.midi = midi
    }

    public var frequency: Double {
        440 * pow(2, Double(midi - 69) / 12)
    }

    public static let rest = Pitch(midi: -1)
    public var isRest: Bool { midi < 0 }
}
