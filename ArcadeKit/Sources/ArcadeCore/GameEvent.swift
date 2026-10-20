import Foundation

public enum GameEvent: Hashable, Sendable {
    case stageStarted(stage: Int)
    case jumped
    case clearedHazard(position: Vector2)
    case smashedHazard(position: Vector2)
    case hazardSpawned(position: Vector2)
    case overclockCollected(position: Vector2)
    case scored(points: Int, position: Vector2)
    case climberDied
    case extraLife
    case stageCleared(stage: Int)
    case gameOver(score: Int)
    case bonusExpiring
}

public enum GamePhase: Hashable, Sendable {
    case attract
    case ready(elapsed: Double)
    case playing
    case dying(elapsed: Double)
    case stageClear(elapsed: Double)
    case gameOver

    public var isInteractive: Bool {
        if case .playing = self { return true }
        return false
    }
}

public struct ScoreBoard: Hashable, Sendable {
    public var score: Int
    public var highScore: Int
    public var lives: Int
    public var stage: Int

    public static let startingLives = 3
    public static let extraLifeThreshold = 10_000

    public init(score: Int = 0, highScore: Int = 0, lives: Int = ScoreBoard.startingLives, stage: Int = 1) {
        self.score = score
        self.highScore = highScore
        self.lives = lives
        self.stage = stage
    }

    public mutating func add(_ points: Int) -> Bool {
        let previousBand = score / ScoreBoard.extraLifeThreshold
        score += points
        highScore = max(highScore, score)
        let band = score / ScoreBoard.extraLifeThreshold
        if band > previousBand {
            lives += 1
            return true
        }
        return false
    }
}
