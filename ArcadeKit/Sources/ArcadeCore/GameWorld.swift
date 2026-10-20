import Foundation

public struct GameWorld: Sendable {
    public private(set) var level: LevelLayout
    public private(set) var climber: Climber
    public private(set) var hazards: [Hazard]
    public private(set) var phase: GamePhase
    public private(set) var board: ScoreBoard
    public private(set) var bonusRemaining: Double
    public private(set) var overclock: Pickup?
    public private(set) var events: [GameEvent]

    private var random: GameRandom
    private var nextHazardID = 0
    private var spawnTimer: Double = 0
    private var bonusWarningSent = false

    public struct Pickup: Hashable, Sendable {
        public var position: Vector2
        public var isCollected: Bool
        public static let size = Vector2(x: 12, y: 10)

        public var rect: Rect {
            Rect.centered(at: Vector2(x: position.x, y: position.y + Pickup.size.y / 2), size: Pickup.size)
        }
    }

    public static let readyDuration: Double = 1.8
    public static let stageClearDuration: Double = 2.6

    public init(stage: Int = 1, highScore: Int = 0, seed: UInt64 = 0xC0FF_EE12_3456_789A) {
        let layout = LevelLayout.stage(stage)
        level = layout
        climber = Climber(position: layout.playerStart, girderID: layout.bottomGirder.id)
        hazards = []
        phase = .attract
        board = ScoreBoard(highScore: highScore, stage: stage)
        bonusRemaining = layout.bonusSeconds
        overclock = Self.makeOverclock(for: layout)
        events = []
        random = GameRandom(seed: seed)
    }

    public var prizeRect: Rect {
        Rect.centered(at: level.prizePosition, size: Vector2(x: 18, y: 20))
    }

    public var bonusFraction: Double {
        guard level.bonusSeconds > 0 else { return 0 }
        return (bonusRemaining / level.bonusSeconds).clamped(to: 0...1)
    }

    public mutating func drainEvents() -> [GameEvent] {
        defer { events.removeAll(keepingCapacity: true) }
        return events
    }

    public mutating func startGame() {
        board = ScoreBoard(highScore: board.highScore, stage: 1)
        loadStage(1)
    }

    public mutating func step(dt: Double, input: InputState) {
        switch phase {
        case .attract, .gameOver:
            if input.start { startGame() }
        case .ready(let elapsed):
            let next = elapsed + dt
            phase = next >= Self.readyDuration ? .playing : .ready(elapsed: next)
        case .playing:
            stepPlaying(dt: dt, input: input)
        case .dying(let elapsed):
            let next = elapsed + dt
            climber.update(dt: dt, input: .neutral, level: level)
            if next >= ClimberMotion.deathDuration {
                advanceAfterDeath()
            } else {
                phase = .dying(elapsed: next)
            }
        case .stageClear(let elapsed):
            let next = elapsed + dt
            if next >= Self.stageClearDuration {
                loadStage(board.stage + 1)
            } else {
                phase = .stageClear(elapsed: next)
            }
        }
    }

    private mutating func stepPlaying(dt: Double, input: InputState) {
        let wasAirborne = !climber.isAlive ? false : isAirborne
        climber.update(dt: dt, input: input, level: level)
        if input.jump, !wasAirborne, isAirborne {
            events.append(.jumped)
        }

        updateHazards(dt: dt)
        spawnTimer -= dt
        if spawnTimer <= 0 {
            spawnHazard()
            spawnTimer = spawnInterval
        }

        collectOverclock()
        resolveHazardContacts()
        updateBonus(dt: dt)

        if climber.isAlive, prizeRect.intersects(climber.hitRect) || reachedTop {
            clearStage()
        }

        if !climber.isAlive {
            phase = .dying(elapsed: 0)
            events.append(.climberDied)
        }
    }

    private var isAirborne: Bool {
        if case .airborne = climber.state { return true }
        return false
    }

    private var reachedTop: Bool {
        guard case .grounded(let id) = climber.state, id == level.topGirder.id else { return false }
        return abs(climber.position.x - level.prizePosition.x) < 14
    }

    private var spawnInterval: Double {
        max(1.1, 3.0 - Double(board.stage - 1) * 0.22)
    }

    private var hazardSpeed: Double {
        Hazard.baseSpeed + Double(board.stage - 1) * 4
    }

    private mutating func updateHazards(dt: Double) {
        for index in hazards.indices {
            hazards[index].update(dt: dt, level: level, speed: hazardSpeed, random: &random)
        }
        hazards.removeAll { hazard in
            if case .smashed(let elapsed) = hazard.state, elapsed >= Hazard.smashDuration {
                return true
            }
            return hazard.isOffscreen
        }
    }

    private mutating func spawnHazard() {
        let top = level.topGirder
        let position = Vector2(x: level.cranePosition.x, y: top.start.y)
        var hazard = Hazard(id: nextHazardID, position: position, girderID: top.id, direction: 1)
        hazard.direction = random.chance(0.5) ? 1 : -1
        hazards.append(hazard)
        nextHazardID += 1
        events.append(.hazardSpawned(position: position))
    }

    private mutating func collectOverclock() {
        guard var pickup = overclock, !pickup.isCollected else { return }
        guard pickup.rect.intersects(climber.hitRect) else { return }
        pickup.isCollected = true
        overclock = pickup
        climber.overclockRemaining = 8
        events.append(.overclockCollected(position: pickup.position))
        award(200, at: pickup.position)
    }

    private mutating func resolveHazardContacts() {
        let hit = climber.hitRect
        for index in hazards.indices {
            guard hazards[index].isActive else { continue }
            let hazardRect = hazards[index].hitRect

            if hazardRect.intersects(hit) {
                if climber.hasOverclock {
                    let position = hazards[index].position
                    hazards[index].smash()
                    events.append(.smashedHazard(position: position))
                    award(300, at: position)
                } else {
                    climber.kill()
                    return
                }
                continue
            }

            guard isAirborne, !hazards[index].hasBeenCleared else { continue }
            let horizontallyAligned = abs(hazardRect.midX - hit.midX) < 11
            let below = hazardRect.maxY <= hit.minY + 2
            if horizontallyAligned, below {
                hazards[index].hasBeenCleared = true
                let position = hazards[index].position
                events.append(.clearedHazard(position: position))
                award(100, at: position)
            }
        }
    }

    private mutating func updateBonus(dt: Double) {
        guard bonusRemaining > 0 else { return }
        bonusRemaining = max(0, bonusRemaining - dt)
        if bonusRemaining <= 8, !bonusWarningSent {
            bonusWarningSent = true
            events.append(.bonusExpiring)
        }
        if bonusRemaining == 0 {
            climber.kill()
        }
    }

    private mutating func award(_ points: Int, at position: Vector2) {
        events.append(.scored(points: points, position: position))
        if board.add(points) {
            events.append(.extraLife)
        }
    }

    private mutating func clearStage() {
        let remaining = Int(bonusRemaining.rounded())
        award(500 + remaining * 10, at: level.prizePosition)
        events.append(.stageCleared(stage: board.stage))
        phase = .stageClear(elapsed: 0)
    }

    private mutating func advanceAfterDeath() {
        board.lives -= 1
        if board.lives <= 0 {
            phase = .gameOver
            events.append(.gameOver(score: board.score))
        } else {
            resetStageEntities()
            phase = .ready(elapsed: 0)
        }
    }

    private mutating func loadStage(_ stage: Int) {
        board.stage = stage
        level = LevelLayout.stage(stage)
        overclock = Self.makeOverclock(for: level)
        resetStageEntities()
        phase = .ready(elapsed: 0)
        events.append(.stageStarted(stage: stage))
    }

    private mutating func resetStageEntities() {
        climber = Climber(position: level.playerStart, girderID: level.bottomGirder.id)
        hazards.removeAll(keepingCapacity: true)
        bonusRemaining = level.bonusSeconds
        bonusWarningSent = false
        spawnTimer = 1.2
        if var pickup = overclock {
            pickup.isCollected = false
            overclock = pickup
        }
    }

    private static func makeOverclock(for level: LevelLayout) -> Pickup? {
        guard level.girders.count > 2 else { return nil }
        let girder = level.girders[2]
        let x = girder.minX + (girder.maxX - girder.minX) * 0.42
        guard let y = girder.surfaceY(atX: x) else { return nil }
        return Pickup(position: Vector2(x: x, y: y), isCollected: false)
    }
}
