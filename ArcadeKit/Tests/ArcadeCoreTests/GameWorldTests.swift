import Foundation
import Testing

@testable import ArcadeCore

@Suite("Game world")
struct GameWorldTests {
    private let step = GameClock.tickDuration

    private func advance(_ world: inout GameWorld, input: InputState = .neutral, seconds: Double) {
        let ticks = Int(seconds / step)
        for _ in 0..<ticks {
            world.step(dt: step, input: input)
        }
    }

    @Test("the world starts in attract mode and waits for a credit")
    func startsInAttract() {
        var world = GameWorld()
        #expect(world.phase == .attract)
        advance(&world, seconds: 2)
        #expect(world.phase == .attract)
    }

    @Test("pressing start begins the ready countdown, then play")
    func startBeginsPlay() {
        var world = GameWorld()
        world.step(dt: step, input: InputState(start: true))
        if case .ready = world.phase {} else {
            Issue.record("expected the ready countdown")
        }
        advance(&world, seconds: GameWorld.readyDuration + 0.1)
        #expect(world.phase == .playing)
    }

    @Test("the bonus timer runs down while playing")
    func bonusRunsDown() {
        var world = GameWorld()
        world.startGame()
        advance(&world, seconds: GameWorld.readyDuration + 1)
        #expect(world.bonusRemaining < world.level.bonusSeconds)
        #expect(world.bonusFraction < 1)
    }

    @Test("letting the bonus timer expire costs a life")
    func bonusExpiryCostsALife() {
        var world = GameWorld()
        world.startGame()
        let lives = world.board.lives
        advance(&world, seconds: world.level.bonusSeconds + GameWorld.readyDuration + 3)
        #expect(world.board.lives < lives)
    }

    @Test("hazards appear once play begins")
    func hazardsSpawn() {
        var world = GameWorld()
        world.startGame()
        advance(&world, seconds: GameWorld.readyDuration + 4)
        #expect(!world.hazards.isEmpty)
    }

    @Test("scoring raises the score and the high score together")
    func scoringUpdatesBoard() {
        var board = ScoreBoard()
        _ = board.add(500)
        #expect(board.score == 500)
        #expect(board.highScore == 500)
    }

    @Test("crossing a score band grants an extra life exactly once")
    func extraLifeIsGrantedOnce() {
        var board = ScoreBoard()
        let belowBand = board.add(ScoreBoard.extraLifeThreshold - 1)
        #expect(!belowBand)
        #expect(board.lives == ScoreBoard.startingLives)
        let crossedBand = board.add(2)
        #expect(crossedBand)
        #expect(board.lives == ScoreBoard.startingLives + 1)
        let sameBand = board.add(10)
        #expect(!sameBand)
    }

    @Test("running out of lives ends the game")
    func gameOverAfterLastLife() {
        var world = GameWorld()
        world.startGame()
        advance(&world, seconds: GameWorld.readyDuration + 0.1)
        for _ in 0..<ScoreBoard.startingLives {
            advance(&world, seconds: world.level.bonusSeconds + 3)
            if world.phase == .gameOver { break }
            advance(&world, seconds: GameWorld.readyDuration + 0.1)
        }
        #expect(world.phase == .gameOver)
        #expect(world.board.lives <= 0)
    }

    @Test("a fresh credit resets the score and lives but keeps the record")
    func restartKeepsHighScore() {
        var world = GameWorld(stage: 1, highScore: 7_000)
        world.startGame()
        #expect(world.board.score == 0)
        #expect(world.board.lives == ScoreBoard.startingLives)
        #expect(world.board.highScore == 7_000)
    }

    @Test("events are drained so each one is handled once")
    func eventsDrainOnce() {
        var world = GameWorld()
        world.startGame()
        advance(&world, seconds: GameWorld.readyDuration + 4)
        let first = world.drainEvents()
        #expect(!first.isEmpty)
        #expect(world.drainEvents().isEmpty)
    }

    @Test("the simulation is deterministic for the same seed and input")
    func simulationIsDeterministic() {
        func run() -> (Int, Double, Int) {
            var world = GameWorld(seed: 42)
            world.startGame()
            advance(&world, input: InputState(horizontal: 1), seconds: 12)
            return (world.board.score, world.bonusRemaining, world.hazards.count)
        }
        let first = run()
        let second = run()
        #expect(first.0 == second.0)
        #expect(first.1 == second.1)
        #expect(first.2 == second.2)
    }
}

@Suite("High score persistence")
struct HighScoreStoreTests {
    @Test("a fresh store starts at zero")
    func freshStoreIsEmpty() {
        #expect(MemoryHighScore().load() == 0)
    }

    @Test("a better score is kept")
    func betterScoreIsKept() {
        let store = MemoryHighScore()
        store.save(1_200)
        #expect(store.load() == 1_200)
    }

    @Test("a worse score never overwrites the record")
    func worseScoreIsIgnored() {
        let store = MemoryHighScore(initial: 5_000)
        store.save(900)
        #expect(store.load() == 5_000)
    }

    @Test("the record carries into a new world")
    func recordSeedsANewWorld() {
        let store = MemoryHighScore(initial: 7_500)
        var world = GameWorld(highScore: store.load())
        world.startGame()
        #expect(world.board.highScore == 7_500)
        #expect(world.board.score == 0)
    }

    @Test("beating the record updates what would be saved")
    func beatingTheRecordRaisesIt() {
        var board = ScoreBoard(highScore: 400)
        _ = board.add(900)
        #expect(board.highScore == 900)
        let store = MemoryHighScore(initial: 400)
        store.save(board.highScore)
        #expect(store.load() == 900)
    }

    @Test("the defaults-backed store round-trips through a suite")
    func defaultsStoreRoundTrips() throws {
        let name = "scrapspire.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removeSuite(named: name) }
        let store = UserDefaultsHighScore(defaults: defaults)
        #expect(store.load() == 0)
        store.save(3_300)
        #expect(store.load() == 3_300)
        store.save(10)
        #expect(store.load() == 3_300)
    }
}
