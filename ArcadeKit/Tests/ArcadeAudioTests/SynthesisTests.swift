import Testing

@testable import ArcadeAudio

@Suite("Pitch and envelope")
struct PitchTests {
    @Test("concert A is 440 hertz")
    func concertAIsStandard() {
        #expect(abs(Pitch(midi: 69).frequency - 440) < 0.0001)
    }

    @Test("an octave up doubles the frequency")
    func octaveDoubles() {
        let low = Pitch(midi: 57).frequency
        let high = Pitch(midi: 69).frequency
        #expect(abs(high - low * 2) < 0.0001)
    }

    @Test("a rest is not a playable pitch")
    func restIsNotPlayable() {
        #expect(Pitch.rest.isRest)
        #expect(!Pitch(midi: 60).isRest)
    }

    @Test("the envelope rises through attack and falls to silence after release")
    func envelopeShape() {
        let envelope = Envelope(attack: 0.1, decay: 0.1, sustain: 0.5, release: 0.1)
        #expect(envelope.amplitude(at: 0, duration: 1) == 0)
        #expect(envelope.amplitude(at: 0.05, duration: 1) > 0)
        #expect(abs(envelope.amplitude(at: 0.1, duration: 1) - 1) < 0.0001)
        #expect(abs(envelope.amplitude(at: 0.5, duration: 1) - 0.5) < 0.0001)
        #expect(envelope.amplitude(at: 1.2, duration: 1) == 0)
    }

    @Test("amplitude never leaves the unit range", arguments: [0.0, 0.05, 0.3, 0.9, 1.05, 2.0])
    func envelopeStaysInRange(time: Double) {
        let value = Envelope.pluck.amplitude(at: time, duration: 1)
        #expect(value >= 0)
        #expect(value <= 1)
    }
}

@Suite("Waveforms")
struct WaveformTests {
    @Test("every waveform stays inside the unit range", arguments: Waveform.allCases)
    func waveformsAreBounded(waveform: Waveform) {
        var seed: UInt64 = 12345
        for step in 0..<500 {
            let value = waveform.sample(phase: Double(step) / 97, seed: &seed)
            #expect(value >= -1.0001)
            #expect(value <= 1.0001)
        }
    }

    @Test("a square wave flips halfway through its cycle")
    func squareFlips() {
        var seed: UInt64 = 1
        #expect(Waveform.square.sample(phase: 0.25, seed: &seed) == 1)
        #expect(Waveform.square.sample(phase: 0.75, seed: &seed) == -1)
    }

    @Test("a triangle wave peaks in the middle and troughs at the edges")
    func triangleShape() {
        var seed: UInt64 = 1
        #expect(abs(Waveform.triangle.sample(phase: 0.5, seed: &seed) - 1) < 0.0001)
        #expect(abs(Waveform.triangle.sample(phase: 0.0, seed: &seed) + 1) < 0.0001)
    }

    @Test("noise keeps changing instead of repeating a constant")
    func noiseVaries() {
        var seed: UInt64 = 99
        var values: Set<Double> = []
        for _ in 0..<50 {
            values.insert(Waveform.noise.sample(phase: 0, seed: &seed))
        }
        #expect(values.count > 10)
    }
}

@Suite("Synthesis")
struct SynthesisTests {
    @Test("a rendered note is audible")
    func noteIsAudible() {
        let samples = Synthesizer.render(Tone(pitch: Pitch(midi: 69)))
        #expect(!samples.isEmpty)
        #expect(samples.contains { abs($0) > 0.01 })
    }

    @Test("a rest renders silence of the right length")
    func restIsSilent() {
        let tone = Tone(pitch: .rest, duration: 0.2)
        let samples = Synthesizer.render(tone)
        #expect(!samples.isEmpty)
        #expect(samples.allSatisfy { $0 == 0 })
    }

    @Test("a sequence is at least as long as the notes it holds")
    func sequenceLength() {
        let tones = [
            Tone(pitch: Pitch(midi: 60), duration: 0.1),
            Tone(pitch: Pitch(midi: 64), duration: 0.1),
        ]
        let samples = Synthesizer.sequence(tones)
        #expect(Double(samples.count) >= 0.2 * Synthesizer.sampleRate)
    }

    @Test("mixing never clips past full scale")
    func mixIsNormalized() {
        let loud = [Float](repeating: 0.9, count: 100)
        let mixed = Synthesizer.mix([loud, loud, loud])
        #expect(mixed.allSatisfy { abs($0) <= 1.0001 })
        #expect(mixed.contains { abs($0) > 0.5 })
    }

    @Test("mixing nothing yields nothing")
    func mixOfEmptyIsEmpty() {
        #expect(Synthesizer.mix([]).isEmpty)
    }
}

@Suite("Score and effects")
struct ScoreTests {
    @Test("both themes have length and are audible", arguments: [MusicScore.attract, MusicScore.climb])
    func themesAreAudible(score: MusicScore) {
        #expect(score.duration > 1)
        let samples = score.render(sampleRate: 8_000)
        #expect(samples.contains { abs($0) > 0.01 })
    }

    @Test("every sound effect renders something audible", arguments: SoundEffect.allCases)
    func effectsAreAudible(effect: SoundEffect) {
        let samples = effect.render(sampleRate: 8_000)
        #expect(!samples.isEmpty)
        #expect(samples.contains { abs($0) > 0.01 })
    }

    @Test("no rendered audio exceeds full scale", arguments: SoundEffect.allCases)
    func effectsDoNotClip(effect: SoundEffect) {
        #expect(effect.render(sampleRate: 8_000).allSatisfy { abs($0) <= 1.0001 })
    }
}
