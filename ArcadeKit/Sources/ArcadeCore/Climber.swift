import Foundation

public enum ClimberState: Hashable, Sendable {
    case grounded(girderID: Int)
    case climbing(ladderID: Int)
    case airborne
    case dying(elapsed: Double)
}

public enum Facing: Int, Hashable, Sendable {
    case left = -1
    case right = 1
}

public struct ClimberMotion: Sendable {
    public static let size = Vector2(x: 11, y: 16)
    public static let walkSpeed: Double = 46
    public static let climbSpeed: Double = 32
    public static let jumpSpeed: Double = 96
    public static let gravity: Double = 360
    public static let deathDuration: Double = 1.6
}

public struct Climber: Sendable {
    public var position: Vector2
    public var velocity: Vector2
    public var state: ClimberState
    public var facing: Facing
    public var animationTime: Double
    public var overclockRemaining: Double

    public init(position: Vector2, girderID: Int) {
        self.position = position
        velocity = .zero
        state = .grounded(girderID: girderID)
        facing = .right
        animationTime = 0
        overclockRemaining = 0
    }

    public var isAlive: Bool {
        if case .dying = state { return false }
        return true
    }

    public var hasOverclock: Bool { overclockRemaining > 0 }

    public var isMoving: Bool {
        switch state {
        case .grounded: abs(velocity.x) > 0.5
        case .climbing: abs(velocity.y) > 0.5
        case .airborne: true
        case .dying: false
        }
    }

    public var bodyRect: Rect {
        Rect(
            origin: Vector2(x: position.x - ClimberMotion.size.x / 2, y: position.y),
            size: ClimberMotion.size)
    }

    public var hitRect: Rect {
        bodyRect.insetBy(dx: 1.5, dy: 1.5)
    }

    public mutating func kill() {
        guard isAlive else { return }
        state = .dying(elapsed: 0)
        velocity = .zero
        overclockRemaining = 0
    }
}

extension Climber {
    public mutating func update(dt: Double, input: InputState, level: LevelLayout) {
        animationTime += dt
        if overclockRemaining > 0 {
            overclockRemaining = max(0, overclockRemaining - dt)
        }

        switch state {
        case .dying(let elapsed):
            state = .dying(elapsed: elapsed + dt)
        case .grounded(let girderID):
            updateGrounded(dt: dt, input: input, level: level, girderID: girderID)
        case .climbing(let ladderID):
            updateClimbing(dt: dt, input: input, level: level, ladderID: ladderID)
        case .airborne:
            updateAirborne(dt: dt, level: level)
        }
    }

    private mutating func updateGrounded(
        dt: Double, input: InputState, level: LevelLayout, girderID: Int
    ) {
        guard let girder = level.girder(id: girderID) else {
            state = .airborne
            return
        }

        if input.jump {
            velocity.y = ClimberMotion.jumpSpeed
            velocity.x = input.horizontal * ClimberMotion.walkSpeed
            state = .airborne
            position.y += 0.5
            return
        }

        if input.isPressingUp, let ladder = ladderUp(level: level, girder: girder) {
            state = .climbing(ladderID: ladder.id)
            position.x = ladder.centerX
            velocity = .zero
            return
        }

        if input.isPressingDown, let ladder = ladderDown(level: level, girder: girder) {
            state = .climbing(ladderID: ladder.id)
            position.x = ladder.centerX
            position.y = min(position.y, ladder.usableTopY)
            velocity = .zero
            return
        }

        velocity.x = input.horizontal * ClimberMotion.walkSpeed
        velocity.y = 0
        if abs(velocity.x) > 0.01 {
            facing = velocity.x < 0 ? .left : .right
        }

        let nextX = position.x + velocity.x * dt
        if let surface = girder.surfaceY(atX: nextX) {
            position.x = nextX
            position.y = surface
        } else {
            position.x = girder.clampedX(nextX)
            if let surface = girder.surfaceY(atX: position.x) {
                position.y = surface
            }
            velocity.x = 0
        }
    }

    private mutating func updateClimbing(
        dt: Double, input: InputState, level: LevelLayout, ladderID: Int
    ) {
        guard let ladder = level.ladders.first(where: { $0.id == ladderID }) else {
            state = .airborne
            return
        }

        position.x = ladder.centerX
        velocity.x = 0
        velocity.y = input.vertical * ClimberMotion.climbSpeed
        position.y += velocity.y * dt

        if position.y >= ladder.topY, !ladder.isBroken {
            position.y = ladder.topY
            if let landing = level.highestGirder(below: position.y + 1, atX: position.x) {
                state = .grounded(girderID: landing.girder.id)
                position.y = landing.surfaceY
            } else {
                state = .airborne
            }
            velocity = .zero
            return
        }

        if position.y >= ladder.usableTopY {
            position.y = ladder.usableTopY
            velocity.y = 0
        }

        if position.y <= ladder.bottomY {
            position.y = ladder.bottomY
            if let landing = level.highestGirder(below: position.y + 1, atX: position.x) {
                state = .grounded(girderID: landing.girder.id)
                position.y = landing.surfaceY
            }
            velocity = .zero
        }
    }

    private mutating func updateAirborne(dt: Double, level: LevelLayout) {
        let previousY = position.y
        velocity.y -= ClimberMotion.gravity * dt
        position.x = (position.x + velocity.x * dt).clamped(to: 0...VirtualViewport.coreSize.x)
        position.y += velocity.y * dt

        guard velocity.y <= 0 else { return }
        for girder in level.girders {
            guard let surface = girder.surfaceY(atX: position.x) else { continue }
            if previousY >= surface - 0.5, position.y <= surface {
                position.y = surface
                velocity = .zero
                state = .grounded(girderID: girder.id)
                return
            }
        }

        if position.y < -40 {
            kill()
        }
    }

    private func ladderUp(level: LevelLayout, girder: Girder) -> Ladder? {
        level.ladders.first { ladder in
            ladder.containsX(position.x) && abs(ladder.bottomY - position.y) < 6
        }
    }

    private func ladderDown(level: LevelLayout, girder: Girder) -> Ladder? {
        level.ladders.first { ladder in
            ladder.containsX(position.x) && !ladder.isBroken
                && abs(ladder.topY - position.y) < 6
        }
    }
}
