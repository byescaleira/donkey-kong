import Foundation

public struct Girder: Hashable, Sendable, Identifiable {
    public let id: Int
    public let start: Vector2
    public let end: Vector2
    public let thickness: Double

    public init(id: Int, start: Vector2, end: Vector2, thickness: Double = 8) {
        self.id = id
        self.start = start
        self.end = end
        self.thickness = thickness
    }

    public var minX: Double { min(start.x, end.x) }
    public var maxX: Double { max(start.x, end.x) }
    public var slope: Double {
        let run = end.x - start.x
        guard abs(run) > 0.0001 else { return 0 }
        return (end.y - start.y) / run
    }

    public var descendsToTheRight: Bool { end.y < start.y }

    public func surfaceY(atX x: Double) -> Double? {
        guard x >= minX - 0.001, x <= maxX + 0.001 else { return nil }
        let run = end.x - start.x
        guard abs(run) > 0.0001 else { return max(start.y, end.y) }
        let t = ((x - start.x) / run).clamped(to: 0...1)
        return start.y + (end.y - start.y) * t
    }

    public func clampedX(_ x: Double) -> Double {
        x.clamped(to: minX...maxX)
    }
}

public struct Ladder: Hashable, Sendable, Identifiable {
    public let id: Int
    public let centerX: Double
    public let bottomY: Double
    public let topY: Double
    public let isBroken: Bool
    public static let width: Double = 14

    public init(id: Int, centerX: Double, bottomY: Double, topY: Double, isBroken: Bool = false) {
        self.id = id
        self.centerX = centerX
        self.bottomY = bottomY
        self.topY = topY
        self.isBroken = isBroken
    }

    public var usableTopY: Double {
        isBroken ? bottomY + (topY - bottomY) * 0.55 : topY
    }

    public var height: Double { topY - bottomY }

    public func containsX(_ x: Double) -> Bool {
        abs(x - centerX) <= Ladder.width / 2
    }

    public func rect() -> Rect {
        Rect(
            x: centerX - Ladder.width / 2, y: bottomY, width: Ladder.width,
            height: usableTopY - bottomY)
    }
}

public struct LevelLayout: Sendable {
    public let stage: Int
    public let girders: [Girder]
    public let ladders: [Ladder]
    public let playerStart: Vector2
    public let prizePosition: Vector2
    public let cranePosition: Vector2
    public let bonusSeconds: Double

    public var topGirder: Girder { girders[girders.count - 1] }
    public var bottomGirder: Girder { girders[0] }

    public func girder(id: Int) -> Girder? {
        girders.first { $0.id == id }
    }

    public func ladders(fromGirder id: Int) -> [Ladder] {
        let bottomY = girders.first { $0.id == id }.map { min($0.start.y, $0.end.y) } ?? 0
        return ladders.filter { abs($0.bottomY - bottomY) < 14 }
    }

    public func highestGirder(below y: Double, atX x: Double) -> (girder: Girder, surfaceY: Double)? {
        var best: (Girder, Double)?
        for girder in girders {
            guard let surface = girder.surfaceY(atX: x), surface <= y + 0.5 else { continue }
            if best == nil || surface > best!.1 {
                best = (girder, surface)
            }
        }
        return best.map { (girder: $0.0, surfaceY: $0.1) }
    }

    public var isTraversable: Bool {
        var reached: Set<Int> = [bottomGirder.id]
        var changed = true
        while changed {
            changed = false
            for ladder in ladders where !ladder.isBroken {
                guard let lower = girder(coveringX: ladder.centerX, atY: ladder.bottomY),
                    let upper = girder(coveringX: ladder.centerX, atY: ladder.topY)
                else { continue }
                if reached.contains(lower.id), !reached.contains(upper.id) {
                    reached.insert(upper.id)
                    changed = true
                }
                if reached.contains(upper.id), !reached.contains(lower.id) {
                    reached.insert(lower.id)
                    changed = true
                }
            }
        }
        return reached.contains(topGirder.id)
    }

    public func girder(coveringX x: Double, atY y: Double) -> Girder? {
        girders.first { girder in
            guard let surface = girder.surfaceY(atX: x) else { return false }
            return abs(surface - y) < 1.5
        }
    }

    public static func stage(_ stage: Int) -> LevelLayout {
        let style = StageStyle.allCases[(max(stage, 1) - 1) % StageStyle.allCases.count]
        return make(stage: stage, style: style)
    }

    public static func make(stage: Int, style: StageStyle) -> LevelLayout {
        let width = VirtualViewport.coreSize.x
        let specs = style.rows
        let baseY: Double = 22
        let spacing = style.spacing

        var girders: [Girder] = []
        var identifier = 0
        for (index, spec) in specs.enumerated() {
            let y = baseY + spacing * Double(index)
            for segment in spec.segments {
                let start = Vector2(
                    x: segment.lowerBound * width,
                    y: y - spec.drop * (segment.lowerBound - 0.5))
                let end = Vector2(
                    x: segment.upperBound * width,
                    y: y - spec.drop * (segment.upperBound - 0.5))
                girders.append(Girder(id: identifier, start: start, end: end))
                identifier += 1
            }
        }

        var ladders: [Ladder] = []
        var ladderID = 0
        for row in 0..<(specs.count - 1) {
            let anchors = style.anchors(forRow: row)
            for (index, fraction) in anchors.enumerated() {
                let x = fraction * width
                let lower = girders.first { $0.minX <= x && x <= $0.maxX && isRow($0, row, baseY, spacing) }
                let upper = girders.first { $0.minX <= x && x <= $0.maxX && isRow($0, row + 1, baseY, spacing) }
                guard let lower, let upper,
                    let bottom = lower.surfaceY(atX: x), let top = upper.surfaceY(atX: x),
                    top - bottom > 14
                else { continue }
                let broken = style.breaksLadder(row: row, index: index, stage: stage)
                ladders.append(
                    Ladder(id: ladderID, centerX: x, bottomY: bottom, topY: top, isBroken: broken))
                ladderID += 1
            }
        }

        let topY = baseY + spacing * Double(specs.count - 1)
        let bonus = max(18, style.bonusSeconds - Double(stage - 1) * 2)
        let start = girders.first { isRow($0, 0, baseY, spacing) } ?? girders[0]
        return LevelLayout(
            stage: stage,
            girders: girders,
            ladders: ladders,
            playerStart: Vector2(x: start.minX + 24, y: start.surfaceY(atX: start.minX + 24) ?? baseY),
            prizePosition: Vector2(x: width / 2 + 26, y: topY + 24),
            cranePosition: Vector2(x: width / 2 - 40, y: topY),
            bonusSeconds: bonus)
    }

    private static func isRow(_ girder: Girder, _ row: Int, _ baseY: Double, _ spacing: Double)
        -> Bool
    {
        let expected = baseY + spacing * Double(row)
        let mid = (girder.start.y + girder.end.y) / 2
        return abs(mid - expected) < spacing / 2
    }
}

public struct RowSpec: Sendable {
    public let segments: [ClosedRange<Double>]
    public let drop: Double

    public init(segments: [ClosedRange<Double>], drop: Double = 0) {
        self.segments = segments
        self.drop = drop
    }
}

public enum StageStyle: String, CaseIterable, Sendable {
    case ascent
    case zigzag
    case towers
    case split
    case gauntlet

    public var title: String {
        switch self {
        case .ascent: "Ascent"
        case .zigzag: "Zigzag"
        case .towers: "Towers"
        case .split: "Split"
        case .gauntlet: "Gauntlet"
        }
    }

    public var spacing: Double {
        switch self {
        case .ascent: 38
        case .zigzag: 34
        case .towers: 38
        case .split: 38
        case .gauntlet: 30
        }
    }

    public var bonusSeconds: Double {
        switch self {
        case .ascent: 46
        case .zigzag: 48
        case .towers: 44
        case .split: 50
        case .gauntlet: 54
        }
    }

    public var rows: [RowSpec] {
        switch self {
        case .ascent:
            [
                RowSpec(segments: [0...1]),
                RowSpec(segments: [0...0.95], drop: 11),
                RowSpec(segments: [0.05...1], drop: -11),
                RowSpec(segments: [0...0.95], drop: 11),
                RowSpec(segments: [0.05...1], drop: -11),
                RowSpec(segments: [0.12...0.88]),
            ]
        case .zigzag:
            [
                RowSpec(segments: [0...1]),
                RowSpec(segments: [0...0.82], drop: 18),
                RowSpec(segments: [0.18...1], drop: -18),
                RowSpec(segments: [0...0.82], drop: 18),
                RowSpec(segments: [0.18...1], drop: -18),
                RowSpec(segments: [0...0.82], drop: 18),
                RowSpec(segments: [0.12...0.88]),
            ]
        case .towers:
            [
                RowSpec(segments: [0...1]),
                RowSpec(segments: [0...0.38, 0.62...1]),
                RowSpec(segments: [0.1...0.46, 0.54...0.9]),
                RowSpec(segments: [0...0.38, 0.62...1]),
                RowSpec(segments: [0.1...0.46, 0.54...0.9]),
                RowSpec(segments: [0.12...0.88]),
            ]
        case .split:
            [
                RowSpec(segments: [0...1]),
                RowSpec(segments: [0...0.44, 0.56...1], drop: 9),
                RowSpec(segments: [0...0.44, 0.56...1], drop: -9),
                RowSpec(segments: [0...0.44, 0.56...1], drop: 9),
                RowSpec(segments: [0...1], drop: -6),
                RowSpec(segments: [0.12...0.88]),
            ]
        case .gauntlet:
            [
                RowSpec(segments: [0...1]),
                RowSpec(segments: [0...0.9], drop: 10),
                RowSpec(segments: [0.1...1], drop: -10),
                RowSpec(segments: [0...0.9], drop: 10),
                RowSpec(segments: [0.1...1], drop: -10),
                RowSpec(segments: [0...0.9], drop: 10),
                RowSpec(segments: [0.1...1], drop: -10),
                RowSpec(segments: [0.12...0.88]),
            ]
        }
    }

    public func anchors(forRow row: Int) -> [Double] {
        switch self {
        case .ascent:
            row.isMultiple(of: 2) ? [0.26, 0.72] : [0.34, 0.78]
        case .zigzag:
            row.isMultiple(of: 2) ? [0.2, 0.66] : [0.36, 0.8]
        case .towers:
            row.isMultiple(of: 2) ? [0.18, 0.82] : [0.3, 0.7]
        case .split:
            [0.18, 0.36, 0.64, 0.82]
        case .gauntlet:
            row.isMultiple(of: 2) ? [0.22, 0.52, 0.8] : [0.34, 0.66]
        }
    }

    public func breaksLadder(row: Int, index: Int, stage: Int) -> Bool {
        guard stage > 1, row > 0 else { return false }
        switch self {
        case .ascent: return index == 1 && row.isMultiple(of: 2)
        case .zigzag: return index == 0 && !row.isMultiple(of: 2)
        case .towers: return false
        case .split: return index == 1 || index == 2
        case .gauntlet: return index.isMultiple(of: 2) && row.isMultiple(of: 3)
        }
    }
}
