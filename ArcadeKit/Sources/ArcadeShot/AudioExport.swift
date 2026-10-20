import ArcadeAudio
import Foundation

enum AudioExport {
    static func wav(from samples: [Float], sampleRate: Double) -> Data {
        var data = Data()
        let frames = samples.count
        let byteCount = frames * 2
        func append(_ string: String) { data.append(contentsOf: Array(string.utf8)) }
        func append32(_ value: UInt32) {
            data.append(contentsOf: [
                UInt8(value & 0xFF), UInt8((value >> 8) & 0xFF),
                UInt8((value >> 16) & 0xFF), UInt8((value >> 24) & 0xFF),
            ])
        }
        func append16(_ value: UInt16) {
            data.append(contentsOf: [UInt8(value & 0xFF), UInt8((value >> 8) & 0xFF)])
        }

        append("RIFF")
        append32(UInt32(36 + byteCount))
        append("WAVE")
        append("fmt ")
        append32(16)
        append16(1)
        append16(1)
        append32(UInt32(sampleRate))
        append32(UInt32(sampleRate) * 2)
        append16(2)
        append16(16)
        append("data")
        append32(UInt32(byteCount))

        for sample in samples {
            let clamped = max(min(sample, 1), -1)
            let value = Int16(clamped * 32_767)
            append16(UInt16(bitPattern: value))
        }
        return data
    }

    static func render(_ name: String) -> [Float] {
        switch name {
        case "attract": return MusicScore.attract.render()
        case "climb": return MusicScore.climb.render()
        case "effects":
            var all: [Float] = []
            let gap = [Float](repeating: 0, count: Int(Synthesizer.sampleRate * 0.18))
            for effect in SoundEffect.allCases {
                all += effect.render() + gap
            }
            return all
        default:
            guard let effect = SoundEffect(rawValue: name) else { return [] }
            return effect.render()
        }
    }

    static func peak(_ samples: [Float]) -> Float {
        samples.reduce(0) { max($0, abs($1)) }
    }
}
