import ArcadeAudio
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
    @ObservationIgnored private let gamepad = GamepadInput()
    @ObservationIgnored public let audio = AudioDirector()
    @ObservationIgnored public let haptics = HapticsDirector()
    @ObservationIgnored private let highScores: any HighScoreStoring
    @ObservationIgnored private let spireScene: SpireScene
    @ObservationIgnored private var clock = GameClock()
    @ObservationIgnored private var frameTimes: [Double] = []
    @ObservationIgnored private var lastFrameTime: Double?

    public init(
        settings: RenderSettings = RenderSettings(),
        highScores: any HighScoreStoring = UserDefaultsHighScore()
    ) {
        self.highScores = highScores
        world = GameWorld(highScore: highScores.load())
        self.settings = settings
        spireScene = SpireScene(size: VirtualViewport.coreSize.cgSize)
    }

    public var controllerName: String? { gamepad.controllerName }

    public var highScore: Int { world.board.highScore }
    public var board: ScoreBoard { world.board }
    public var phase: GamePhase { world.phase }

    public func start() {
        audio.start()
        haptics.prepare()
        world.startGame()
        clock.reset()
    }

    public var isMusicEnabled: Bool {
        get { audio.isMusicEnabled }
        set { audio.isMusicEnabled = newValue }
    }

    public var isEffectsEnabled: Bool {
        get { audio.isEffectsEnabled }
        set { audio.isEffectsEnabled = newValue }
    }

    public var isHapticsEnabled: Bool {
        get { haptics.isEnabled }
        set { haptics.isEnabled = newValue }
    }

    public func applyReduceMotion(_ isReduced: Bool) {
        guard isReduced else { return }
        settings.crt.curvature = 0
        settings.crt.aberration = 0
        settings.crt.bloom = min(settings.crt.bloom, 0.15)
    }

    public func togglePause() {
        isPaused.toggle()
        if !isPaused { clock.reset() }
    }

    private func handle(events: [GameEvent]) {
        audio.handle(events)
        haptics.handle(events)
        highScores.save(world.board.highScore)
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
            spireScene.sync(world: world, time: time)
            return
        }

        gamepad.poll(into: input)

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
        audio.update(phase: world.phase)
        spireScene.sync(world: world, time: time)
    }

    public func reportFrame(renderSize: Vector2Int, outputSize: Vector2Int, usedMetalFX: Bool) {
        stats.renderWidth = renderSize.x
        stats.renderHeight = renderSize.y
        stats.outputWidth = outputSize.x
        stats.outputHeight = outputSize.y
        stats.usesMetalFX = usedMetalFX
    }
}
