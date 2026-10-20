import Testing

@testable import ArcadeCore

@Suite("Climber movement")
struct ClimberTests {
    private let level = LevelLayout.stage(1)
    private let step = GameClock.tickDuration

    private func makeClimber() -> Climber {
        Climber(position: level.playerStart, girderID: level.bottomGirder.id)
    }

    private func advance(
        _ climber: inout Climber, input: InputState, ticks: Int, level: LevelLayout? = nil
    ) {
        let layout = level ?? self.level
        for _ in 0..<ticks {
            climber.update(dt: step, input: input, level: layout)
        }
    }

    @Test("walking right moves the climber and faces it right")
    func walkingRight() {
        var climber = makeClimber()
        let startX = climber.position.x
        advance(&climber, input: InputState(horizontal: 1), ticks: 30)
        #expect(climber.position.x > startX)
        #expect(climber.facing == .right)
    }

    @Test("walking left faces the climber left")
    func walkingLeftFaces() {
        var climber = makeClimber()
        advance(&climber, input: InputState(horizontal: 1), ticks: 30)
        advance(&climber, input: InputState(horizontal: -1), ticks: 10)
        #expect(climber.facing == .left)
    }

    @Test("the climber cannot walk past the end of a girder")
    func girderEndsStopWalking() {
        var climber = makeClimber()
        advance(&climber, input: InputState(horizontal: -1), ticks: 200)
        #expect(climber.position.x >= level.bottomGirder.minX - 0.001)
    }

    @Test("jumping leaves the ground and gravity brings the climber back")
    func jumpingReturnsToGround() {
        var climber = makeClimber()
        let groundY = climber.position.y
        climber.update(dt: step, input: InputState(jump: true), level: level)
        if case .airborne = climber.state {} else {
            Issue.record("expected the climber to be airborne after jumping")
        }
        advance(&climber, input: .neutral, ticks: 120)
        if case .grounded = climber.state {} else {
            Issue.record("expected the climber to land")
        }
        #expect(abs(climber.position.y - groundY) < 1)
    }

    @Test("pressing up on a ladder starts a climb and snaps to the rails")
    func climbingSnapsToLadder() throws {
        let ladder = try #require(
            level.ladders.min { abs($0.bottomY - level.playerStart.y) < abs($1.bottomY - level.playerStart.y) })
        var climber = Climber(position: Vector2(x: ladder.centerX, y: ladder.bottomY), girderID: level.bottomGirder.id)
        climber.update(dt: step, input: InputState(vertical: 1), level: level)
        if case .climbing(let id) = climber.state {
            #expect(id == ladder.id)
        } else {
            Issue.record("expected the climber to be on the ladder")
        }
        #expect(abs(climber.position.x - ladder.centerX) < 0.001)
    }

    @Test("a full climb lands the climber on the girder above")
    func climbReachesNextGirder() throws {
        let ladder = try #require(level.ladders.first { !$0.isBroken })
        var climber = Climber(position: Vector2(x: ladder.centerX, y: ladder.bottomY), girderID: 0)
        advance(&climber, input: InputState(vertical: 1), ticks: 300)
        if case .grounded = climber.state {} else {
            Issue.record("expected the climber to top out on a girder")
        }
        #expect(climber.position.y >= ladder.topY - 0.5)
    }

    @Test("a broken ladder stops the climb short of the top")
    func brokenLadderBlocksTheClimb() {
        let ladder = Ladder(id: 99, centerX: 100, bottomY: 50, topY: 100, isBroken: true)
        let layout = LevelLayout(
            stage: 1,
            girders: [
                Girder(id: 0, start: Vector2(x: 0, y: 50), end: Vector2(x: 224, y: 50)),
                Girder(id: 1, start: Vector2(x: 0, y: 100), end: Vector2(x: 224, y: 100)),
            ],
            ladders: [ladder], playerStart: Vector2(x: 100, y: 50),
            prizePosition: Vector2(x: 100, y: 140), cranePosition: .zero, bonusSeconds: 40)
        var climber = Climber(position: Vector2(x: 100, y: 50), girderID: 0)
        advance(&climber, input: InputState(vertical: 1), ticks: 300, level: layout)
        #expect(climber.position.y <= ladder.usableTopY + 0.001)
        if case .climbing = climber.state {} else {
            Issue.record("expected the climber to still be stuck on the broken ladder")
        }
    }

    @Test("falling off the world kills the climber")
    func fallingOffTheWorldKills() {
        let layout = LevelLayout(
            stage: 1, girders: [Girder(id: 0, start: Vector2(x: 0, y: 10), end: Vector2(x: 20, y: 10))],
            ladders: [], playerStart: Vector2(x: 10, y: 10), prizePosition: Vector2(x: 10, y: 60),
            cranePosition: .zero, bonusSeconds: 40)
        var climber = Climber(position: Vector2(x: 200, y: 10), girderID: 0)
        climber.state = .airborne
        advance(&climber, input: .neutral, ticks: 400, level: layout)
        #expect(!climber.isAlive)
    }

    @Test("the overclock timer runs down and expires")
    func overclockExpires() {
        var climber = makeClimber()
        climber.overclockRemaining = 0.1
        #expect(climber.hasOverclock)
        advance(&climber, input: .neutral, ticks: 12)
        #expect(!climber.hasOverclock)
    }

    @Test("a dead climber ignores input")
    func deadClimberIgnoresInput() {
        var climber = makeClimber()
        climber.kill()
        let position = climber.position
        advance(&climber, input: InputState(horizontal: 1, jump: true), ticks: 30)
        #expect(climber.position == position)
    }
}
