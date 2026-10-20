import ArcadeCore
import ArcadeRender
import ArcadeScene
import Observation
import SpriteKit
import SwiftUI

public struct FrameStats: Hashable, Sendable {
    public var framesPerSecond: Double = 0
    public var renderWidth = 0
    public var renderHeight = 0
    public var outputWidth = 0
    public var outputHeight = 0
    public var usesMetalFX = false

    public var renderDescription: String { "\(renderWidth)×\(renderHeight)" }
    public var outputDescription: String { "\(outputWidth)×\(outputHeight)" }
}

@MainActor @Observable
public final class GameSession {
    public private(set) var world: GameWorld
    public private(set) var stats = FrameStats()
    public var settings: RenderSettings
    public var isPaused = false

    @ObservationIgnored public let input = InputBuffer()
    @ObservationIgnored private let spireScene: SpireScene
    @ObservationIgnored private var clock = GameClock()
    @ObservationIgnored private var frameTimes: [Double] = []
    @ObservationIgnored private var lastFrameTime: Double?

    public init(settings: RenderSettings = RenderSettings()) {
        world = GameWorld()
        self.settings = settings
        spireScene = SpireScene(size: VirtualViewport.coreSize.cgSize)
    }

    public var highScore: Int { world.board.highScore }
    public var board: ScoreBoard { world.board }
    public var phase: GamePhase { world.phase }

    public func start() {
        world.startGame()
        clock.reset()
    }

    public func togglePause() {
        isPaused.toggle()
        if !isPaused { clock.reset() }
    }

    private func handle(events: [GameEvent]) {
        for event in events {
            switch event {
            case .scored(let points, let position):
                spireScene.emitScorePopup(points: points, at: position)
            case .smashedHazard(let position):
                spireScene.emitBurst(at: position, color: ArcadePalette.rust)
            case .overclockCollected(let position):
                spireScene.emitBurst(at: position, color: ArcadePalette.signal)
            case .climberDied:
                spireScene.emitBurst(at: world.climber.position, color: ArcadePalette.accent)
            default:
                break
            }
        }
    }

    private func updateStats(time: Double) {
        defer { lastFrameTime = time }
        guard let lastFrameTime, time > lastFrameTime else { return }
        frameTimes.append(time - lastFrameTime)
        if frameTimes.count > 45 { frameTimes.removeFirst(frameTimes.count - 45) }
        let total = frameTimes.reduce(0, +)
        guard total > 0 else { return }
        stats.framesPerSecond = Double(frameTimes.count) / total
    }
}

extension GameSession: FrameDriver {
    public var scene: SKScene { spireScene }
    public var renderSettings: RenderSettings { settings }

    public func advance(to time: Double, viewport: VirtualViewport) {
        spireScene.apply(viewport: viewport)
        updateStats(time: time)

        guard !isPaused else {
            clock.reset()
            spireScene.sync(world: world)
            return
        }

        let steps = clock.advance(to: time)
        if steps > 0 {
            var state = input.consume()
            for step in 0..<steps {
                world.step(dt: GameClock.tickDuration, input: state)
                if step == 0 {
                    state.jump = false
                    state.start = false
                }
            }
            handle(events: world.drainEvents())
        }
        spireScene.sync(world: world)
    }

    public func reportFrame(renderSize: Vector2Int, outputSize: Vector2Int, usedMetalFX: Bool) {
        stats.renderWidth = renderSize.x
        stats.renderHeight = renderSize.y
        stats.outputWidth = outputSize.x
        stats.outputHeight = outputSize.y
        stats.usesMetalFX = usedMetalFX
    }
}
