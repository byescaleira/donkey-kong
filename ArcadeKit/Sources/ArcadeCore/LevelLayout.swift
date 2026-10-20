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

    public static func stage(_ stage: Int) -> LevelLayout {
        let rows = 6
        let baseY: Double = 22
        let spacing: Double = 38
        let width = VirtualViewport.coreSize.x
        var girders: [Girder] = []
        var ladders: [Ladder] = []

        girders.append(Girder(id: 0, start: Vector2(x: 0, y: baseY), end: Vector2(x: width, y: baseY)))

        for row in 1..<(rows - 1) {
            let y = baseY + spacing * Double(row)
            let descendsRight = row.isMultiple(of: 2)
            let drop: Double = 10
            let inset: Double = 12
            let left = Vector2(x: descendsRight ? 0 : inset, y: descendsRight ? y + drop : y)
            let right = Vector2(
                x: descendsRight ? width - inset : width, y: descendsRight ? y : y + drop)
            girders.append(Girder(id: row, start: left, end: right))
        }

        let topY = baseY + spacing * Double(rows - 1)
        girders.append(
            Girder(id: rows - 1, start: Vector2(x: 28, y: topY), end: Vector2(x: width - 28, y: topY)))

        var ladderID = 0
        for row in 0..<(rows - 1) {
            let lower = girders[row]
            let upper = girders[row + 1]
            let anchors: [Double] =
                row.isMultiple(of: 2) ? [0.26, 0.72] : [0.34, 0.78]
            for (index, fraction) in anchors.enumerated() {
                let span = min(lower.maxX, upper.maxX) - max(lower.minX, upper.minX)
                guard span > Ladder.width * 2 else { continue }
                let x = max(lower.minX, upper.minX) + span * fraction
                guard let bottom = lower.surfaceY(atX: x), let top = upper.surfaceY(atX: x) else {
                    continue
                }
                guard top - bottom > 12 else { continue }
                let broken = stage > 1 && row > 0 && index == 1 && row.isMultiple(of: 2)
                ladders.append(
                    Ladder(id: ladderID, centerX: x, bottomY: bottom, topY: top, isBroken: broken))
                ladderID += 1
            }
        }

        let bonus = max(20, 46 - Double(stage - 1) * 4)
        return LevelLayout(
            stage: stage,
            girders: girders,
            ladders: ladders,
            playerStart: Vector2(x: 24, y: baseY),
            prizePosition: Vector2(x: width / 2 + 26, y: topY + 24),
            cranePosition: Vector2(x: width / 2 - 40, y: topY),
            bonusSeconds: bonus)
    }
}
