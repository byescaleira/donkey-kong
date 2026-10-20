import Foundation

public struct MusicScore: Sendable {
    public let tempo: Double
    public let lead: [Tone]
    public let bass: [Tone]

    public init(tempo: Double, lead: [Tone], bass: [Tone]) {
        self.tempo = tempo
        self.lead = lead
        self.bass = bass
    }

    public var duration: Double {
        max(lead.reduce(0) { $0 + $1.duration }, bass.reduce(0) { $0 + $1.duration })
    }

    public func render(sampleRate: Double = Synthesizer.sampleRate) -> [Float] {
        Synthesizer.mix([
            Synthesizer.sequence(lead, sampleRate: sampleRate),
            Synthesizer.sequence(bass, sampleRate: sampleRate),
        ])
    }
}

enum Step {
    static func lead(_ midi: Int, _ beats: Double, beat: Double, gain: Double = 0.34) -> Tone {
        Tone(
            pitch: midi < 0 ? .rest : Pitch(midi: midi), waveform: .square, envelope: .pluck,
            duration: beats * beat, gain: gain)
    }

    static func bass(_ midi: Int, _ beats: Double, beat: Double, gain: Double = 0.4) -> Tone {
        Tone(
            pitch: midi < 0 ? .rest : Pitch(midi: midi), waveform: .triangle, envelope: .pad,
            duration: beats * beat, gain: gain)
    }
}

extension MusicScore {
    public static let attract: MusicScore = {
        let beat = 60.0 / 108 / 2
        let melody: [(Int, Double)] = [
            (69, 1), (72, 1), (76, 1), (72, 1),
            (74, 1), (72, 1), (69, 2),
            (67, 1), (71, 1), (74, 1), (71, 1),
            (72, 2), (-1, 2),
        ]
        let under: [(Int, Double)] = [
            (45, 2), (45, 2), (50, 2), (45, 2),
            (43, 2), (43, 2), (48, 2), (48, 2),
        ]
        return MusicScore(
            tempo: 108,
            lead: melody.map { Step.lead($0.0, $0.1, beat: beat) },
            bass: under.map { Step.bass($0.0, $0.1, beat: beat) })
    }()

    public static let climb: MusicScore = {
        let beat = 60.0 / 140 / 2
        let melody: [(Int, Double)] = [
            (69, 1), (76, 1), (74, 1), (72, 1),
            (69, 1), (72, 1), (74, 1), (76, 1),
            (77, 1), (76, 1), (74, 1), (72, 1),
            (71, 1), (69, 1), (67, 2),
            (69, 1), (76, 1), (74, 1), (72, 1),
            (69, 1), (72, 1), (76, 1), (79, 1),
            (81, 2), (79, 2),
            (76, 2), (-1, 2),
        ]
        let under: [(Int, Double)] = [
            (45, 1), (45, 1), (52, 1), (45, 1),
            (43, 1), (43, 1), (50, 1), (43, 1),
            (41, 1), (41, 1), (48, 1), (41, 1),
            (40, 1), (40, 1), (47, 1), (47, 1),
            (45, 1), (45, 1), (52, 1), (45, 1),
            (43, 1), (43, 1), (50, 1), (43, 1),
            (48, 2), (47, 2), (45, 4),
        ]
        return MusicScore(
            tempo: 140,
            lead: melody.map { Step.lead($0.0, $0.1, beat: beat) },
            bass: under.map { Step.bass($0.0, $0.1, beat: beat) })
    }()
}

public enum SoundEffect: String, CaseIterable, Sendable {
    case jump
    case land
    case climb
    case cleared
    case smash
    case pickup
    case score
    case death
    case stageClear
    case extraLife
    case warning
    case credit

    public var tones: [Tone] {
        switch self {
        case .jump:
            [Tone(pitch: Pitch(midi: 72), waveform: .pulse, envelope: .blip, duration: 0.1,
                  gain: 0.4, bend: 0.5)]
        case .land:
            [Tone(pitch: Pitch(midi: 48), waveform: .noise, envelope: .blip, duration: 0.06,
                  gain: 0.25)]
        case .climb:
            [Tone(pitch: Pitch(midi: 64), waveform: .square, envelope: .blip, duration: 0.05,
                  gain: 0.18)]
        case .cleared:
            [Tone(pitch: Pitch(midi: 79), waveform: .pulse, envelope: .blip, duration: 0.07, gain: 0.4),
             Tone(pitch: Pitch(midi: 86), waveform: .pulse, envelope: .blip, duration: 0.09, gain: 0.4)]
        case .smash:
            [Tone(pitch: Pitch(midi: 52), waveform: .noise, envelope: .pluck, duration: 0.16,
                  gain: 0.45, bend: -0.4)]
        case .pickup:
            [Tone(pitch: Pitch(midi: 76), waveform: .square, envelope: .blip, duration: 0.06, gain: 0.4),
             Tone(pitch: Pitch(midi: 83), waveform: .square, envelope: .blip, duration: 0.06, gain: 0.4),
             Tone(pitch: Pitch(midi: 88), waveform: .square, envelope: .pluck, duration: 0.12, gain: 0.4)]
        case .score:
            [Tone(pitch: Pitch(midi: 84), waveform: .pulse, envelope: .blip, duration: 0.05, gain: 0.3)]
        case .death:
            [Tone(pitch: Pitch(midi: 69), waveform: .square, envelope: .pluck, duration: 0.14, gain: 0.4),
             Tone(pitch: Pitch(midi: 64), waveform: .square, envelope: .pluck, duration: 0.14, gain: 0.4),
             Tone(pitch: Pitch(midi: 59), waveform: .square, envelope: .pluck, duration: 0.18, gain: 0.4),
             Tone(pitch: Pitch(midi: 52), waveform: .sawtooth, envelope: .pad, duration: 0.4,
                  gain: 0.4, bend: -0.5)]
        case .stageClear:
            [Tone(pitch: Pitch(midi: 72), waveform: .square, envelope: .pluck, duration: 0.12, gain: 0.4),
             Tone(pitch: Pitch(midi: 76), waveform: .square, envelope: .pluck, duration: 0.12, gain: 0.4),
             Tone(pitch: Pitch(midi: 79), waveform: .square, envelope: .pluck, duration: 0.12, gain: 0.4),
             Tone(pitch: Pitch(midi: 84), waveform: .square, envelope: .pad, duration: 0.34, gain: 0.45)]
        case .extraLife:
            [Tone(pitch: Pitch(midi: 81), waveform: .pulse, envelope: .blip, duration: 0.07, gain: 0.4),
             Tone(pitch: Pitch(midi: 88), waveform: .pulse, envelope: .pluck, duration: 0.2, gain: 0.45)]
        case .warning:
            [Tone(pitch: Pitch(midi: 60), waveform: .pulse, envelope: .blip, duration: 0.09, gain: 0.35),
             Tone(pitch: .rest, duration: 0.06),
             Tone(pitch: Pitch(midi: 60), waveform: .pulse, envelope: .blip, duration: 0.09, gain: 0.35)]
        case .credit:
            [Tone(pitch: Pitch(midi: 67), waveform: .square, envelope: .blip, duration: 0.07, gain: 0.4),
             Tone(pitch: Pitch(midi: 74), waveform: .square, envelope: .pluck, duration: 0.16, gain: 0.4)]
        }
    }

    public func render(sampleRate: Double = Synthesizer.sampleRate) -> [Float] {
        Synthesizer.sequence(tones, sampleRate: sampleRate)
    }
}
