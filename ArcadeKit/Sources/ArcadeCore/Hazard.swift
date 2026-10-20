import Foundation

public enum HazardState: Hashable, Sendable {
    case rolling(girderID: Int)
    case falling
    case descending(ladderID: Int)
    case smashed(elapsed: Double)
}

public struct Hazard: Sendable, Identifiable {
    public static let size = Vector2(x: 10, y: 10)
    public static let baseSpeed: Double = 40
    public static let fallGravity: Double = 300
    public static let descendSpeed: Double = 52
    public static let smashDuration: Double = 0.45

    public let id: Int
    public var position: Vector2
    public var velocity: Vector2
    public var state: HazardState
    public var direction: Double
    public var spin: Double
    public var hasBeenCleared: Bool

    public init(id: Int, position: Vector2, girderID: Int, direction: Double) {
        self.id = id
        self.position = position
        velocity = .zero
        state = .rolling(girderID: girderID)
        self.direction = direction
        spin = 0
        hasBeenCleared = false
    }

    public var isActive: Bool {
        if case .smashed = state { return false }
        return true
    }

    public var hitRect: Rect {
        Rect.centered(at: Vector2(x: position.x, y: position.y + Hazard.size.y / 2), size: Hazard.size)
            .insetBy(dx: 1, dy: 1)
    }

    public mutating func smash() {
        guard isActive else { return }
        state = .smashed(elapsed: 0)
        velocity = .zero
    }
}

extension Hazard {
    public mutating func update(dt: Double, level: LevelLayout, speed: Double, random: inout GameRandom) {
        switch state {
        case .smashed(let elapsed):
            state = .smashed(elapsed: elapsed + dt)
        case .rolling(let girderID):
            updateRolling(dt: dt, level: level, speed: speed, girderID: girderID, random: &random)
        case .falling:
            updateFalling(dt: dt, level: level)
        case .descending(let ladderID):
            updateDescending(dt: dt, level: level, ladderID: ladderID)
        }
    }

    private mutating func updateRolling(
        dt: Double, level: LevelLayout, speed: Double, girderID: Int, random: inout GameRandom
    ) {
        guard let girder = level.girder(id: girderID) else {
            state = .falling
            return
        }

        if abs(girder.slope) > 0.001 {
            direction = girder.descendsToTheRight ? 1 : -1
        }

        let nextX = position.x + direction * speed * dt
        spin += direction * speed * dt * 0.09

        guard let surface = girder.surfaceY(atX: nextX) else {
            state = .falling
            position.x = nextX
            velocity = Vector2(x: direction * speed * 0.45, y: 0)
            return
        }

        position.x = nextX
        position.y = surface

        for ladder in level.ladders where ladder.containsX(position.x) && !ladder.isBroken {
            guard abs(ladder.topY - position.y) < 4, ladder.height > 14 else { continue }
            if random.chance(0.22) {
                state = .descending(ladderID: ladder.id)
                position.x = ladder.centerX
                velocity = .zero
                return
            }
        }
    }

    private mutating func updateFalling(dt: Double, level: LevelLayout) {
        let previousY = position.y
        velocity.y -= Hazard.fallGravity * dt
        position.x += velocity.x * dt
        position.y += velocity.y * dt

        guard velocity.y <= 0 else { return }
        for girder in level.girders {
            guard let surface = girder.surfaceY(atX: position.x) else { continue }
            if previousY >= surface - 0.5, position.y <= surface {
                position.y = surface
                velocity = .zero
                direction = girder.descendsToTheRight ? 1 : (girder.slope == 0 ? direction : -1)
                state = .rolling(girderID: girder.id)
                return
            }
        }
    }

    private mutating func updateDescending(dt: Double, level: LevelLayout, ladderID: Int) {
        guard let ladder = level.ladders.first(where: { $0.id == ladderID }) else {
            state = .falling
            return
        }

        position.x = ladder.centerX
        position.y -= Hazard.descendSpeed * dt
        spin -= Hazard.descendSpeed * dt * 0.09

        if position.y <= ladder.bottomY {
            position.y = ladder.bottomY
            if let landing = level.highestGirder(below: position.y + 1, atX: position.x) {
                direction = landing.girder.descendsToTheRight ? 1 : -1
                state = .rolling(girderID: landing.girder.id)
            } else {
                state = .falling
            }
        }
    }

    public var isOffscreen: Bool {
        position.y < -30 || position.x < -30 || position.x > VirtualViewport.coreSize.x + 30
    }
}

public struct GameRandom: Sendable {
    private var state: UInt64

    public init(seed: UInt64 = 0x9E37_79B9_7F4A_7C15) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    public mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 0x2545_F491_4F6C_DD1D
    }

    public mutating func unit() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }

    public mutating func chance(_ probability: Double) -> Bool {
        unit() < probability
    }

    public mutating func range(_ bounds: ClosedRange<Double>) -> Double {
        bounds.lowerBound + unit() * (bounds.upperBound - bounds.lowerBound)
    }
}
