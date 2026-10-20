import Testing

@testable import ArcadeCore

@Suite("Level geometry")
struct LevelTests {
    @Test("a sloped girder interpolates its surface height")
    func girderInterpolates() throws {
        let girder = Girder(id: 0, start: Vector2(x: 0, y: 100), end: Vector2(x: 100, y: 80))
        #expect(girder.surfaceY(atX: 0) == 100)
        #expect(girder.surfaceY(atX: 100) == 80)
        let middle = try #require(girder.surfaceY(atX: 50))
        #expect(abs(middle - 90) < 0.001)
    }

    @Test("a girder has no surface outside its span")
    func girderHasNoSurfaceOutside() {
        let girder = Girder(id: 0, start: Vector2(x: 20, y: 10), end: Vector2(x: 80, y: 10))
        #expect(girder.surfaceY(atX: 10) == nil)
        #expect(girder.surfaceY(atX: 90) == nil)
    }

    @Test("slope direction tells a hazard which way to roll")
    func slopeDirection() {
        let right = Girder(id: 0, start: Vector2(x: 0, y: 100), end: Vector2(x: 100, y: 80))
        let left = Girder(id: 1, start: Vector2(x: 0, y: 80), end: Vector2(x: 100, y: 100))
        #expect(right.descendsToTheRight)
        #expect(!left.descendsToTheRight)
    }

    @Test("a broken ladder cannot be climbed all the way")
    func brokenLadderStopsShort() {
        let ladder = Ladder(id: 0, centerX: 50, bottomY: 0, topY: 40, isBroken: true)
        #expect(ladder.usableTopY < ladder.topY)
        #expect(ladder.usableTopY > ladder.bottomY)
    }

    @Test("every stage has girders, ladders and a reachable prize")
    func stagesAreWellFormed() {
        for stage in 1...6 {
            let level = LevelLayout.stage(stage)
            #expect(level.girders.count >= 4)
            #expect(!level.ladders.isEmpty)
            #expect(level.prizePosition.y > level.topGirder.start.y)
            #expect(level.bonusSeconds > 0)
        }
    }

    @Test("later stages give less bonus time")
    func laterStagesAreTighter() {
        #expect(LevelLayout.stage(4).bonusSeconds < LevelLayout.stage(1).bonusSeconds)
    }

    @Test("every ladder connects two girder surfaces")
    func laddersConnectGirders() {
        let level = LevelLayout.stage(1)
        for ladder in level.ladders {
            let bottom = level.girders.contains { girder in
                guard let surface = girder.surfaceY(atX: ladder.centerX) else { return false }
                return abs(surface - ladder.bottomY) < 0.01
            }
            let top = level.girders.contains { girder in
                guard let surface = girder.surfaceY(atX: ladder.centerX) else { return false }
                return abs(surface - ladder.topY) < 0.01
            }
            #expect(bottom)
            #expect(top)
        }
    }

    @Test("the highest girder below a point is found for landing")
    func landingSearchPicksHighestBelow() throws {
        let level = LevelLayout.stage(1)
        let x = 100.0
        let landing = try #require(level.highestGirder(below: 200, atX: x))
        #expect(landing.surfaceY <= 200)
        for girder in level.girders {
            guard let surface = girder.surfaceY(atX: x), surface <= 200 else { continue }
            #expect(surface <= landing.surfaceY + 0.001)
        }
    }
}

@Suite("Stage variety")
struct StageStyleTests {
    @Test("every style produces a level that can be climbed to the top",
          arguments: StageStyle.allCases)
    func everyStyleIsTraversable(style: StageStyle) {
        for stage in 1...6 {
            let level = LevelLayout.make(stage: stage, style: style)
            #expect(level.isTraversable, "\(style.title) stage \(stage) cannot be finished")
        }
    }

    @Test("every stage of a long run can be finished")
    func longRunStaysPlayable() {
        for stage in 1...20 {
            #expect(LevelLayout.stage(stage).isTraversable, "stage \(stage) cannot be finished")
        }
    }

    @Test("consecutive stages do not repeat the same geometry")
    func consecutiveStagesDiffer() {
        let first = LevelLayout.stage(1)
        let second = LevelLayout.stage(2)
        let shapes = { (level: LevelLayout) in
            level.girders.map { "\(Int($0.start.x)),\(Int($0.start.y)),\(Int($0.end.x)),\(Int($0.end.y))" }
        }
        #expect(shapes(first) != shapes(second))
    }

    @Test("the style cycle covers every style before repeating")
    func cycleCoversEveryStyle() {
        var seen: Set<String> = []
        for stage in 1...StageStyle.allCases.count {
            let shapes = LevelLayout.stage(stage).girders.count
            seen.insert("\(stage)-\(shapes)")
        }
        #expect(seen.count == StageStyle.allCases.count)
    }

    @Test("every style has a reachable prize above its top girder",
          arguments: StageStyle.allCases)
    func prizeSitsAboveTheTop(style: StageStyle) {
        let level = LevelLayout.make(stage: 1, style: style)
        #expect(level.prizePosition.y > level.topGirder.start.y)
        #expect(level.prizePosition.x >= 0)
        #expect(level.prizePosition.x <= VirtualViewport.coreSize.x)
    }

    @Test("the player always starts standing on the bottom girder",
          arguments: StageStyle.allCases)
    func playerStartsGrounded(style: StageStyle) throws {
        let level = LevelLayout.make(stage: 1, style: style)
        let surface = try #require(level.bottomGirder.surfaceY(atX: level.playerStart.x))
        #expect(abs(surface - level.playerStart.y) < 1)
    }

    @Test("every ladder joins two real girder surfaces", arguments: StageStyle.allCases)
    func laddersJoinGirders(style: StageStyle) {
        let level = LevelLayout.make(stage: 2, style: style)
        #expect(!level.ladders.isEmpty)
        for ladder in level.ladders {
            #expect(level.girder(coveringX: ladder.centerX, atY: ladder.bottomY) != nil)
            #expect(level.girder(coveringX: ladder.centerX, atY: ladder.topY) != nil)
        }
    }

    @Test("later stages give less time than the first")
    func laterStagesAreTighter() {
        let early = LevelLayout.make(stage: 1, style: .ascent)
        let late = LevelLayout.make(stage: 8, style: .ascent)
        #expect(late.bonusSeconds < early.bonusSeconds)
        #expect(late.bonusSeconds >= 18)
    }
}
