import ArcadeCore
import Foundation

@MainActor
public final class AudioDirector {
    public var isMusicEnabled = true {
        didSet { applyMusicSetting() }
    }
    public var isEffectsEnabled = true {
        didSet { engine?.effectsVolume = isEffectsEnabled ? effectsVolume : 0 }
    }
    public var musicVolume: Double = 0.45 {
        didSet { applyMusicSetting() }
    }
    public var effectsVolume: Double = 0.8 {
        didSet { engine?.effectsVolume = isEffectsEnabled ? effectsVolume : 0 }
    }

    private let engine: AudioEngine?
    private var currentTheme: Theme = .none

    private enum Theme {
        case none
        case attract
        case climb
    }

    public init(engine: AudioEngine? = AudioEngine()) {
        self.engine = engine
    }

    public var isAvailable: Bool { engine?.isRunning == true }

    public func start() {
        guard let engine else { return }
        engine.prepare()
        engine.start()
        applyMusicSetting()
        engine.effectsVolume = isEffectsEnabled ? effectsVolume : 0
    }

    public func stop() {
        engine?.stop()
        currentTheme = .none
    }

    public func handle(_ events: [GameEvent]) {
        guard let engine else { return }
        for event in events {
            switch event {
            case .jumped: engine.play(.jump)
            case .clearedHazard: engine.play(.cleared)
            case .smashedHazard: engine.play(.smash)
            case .overclockCollected: engine.play(.pickup)
            case .scored: engine.play(.score)
            case .climberDied: engine.play(.death)
            case .extraLife: engine.play(.extraLife)
            case .bonusExpiring: engine.play(.warning)
            case .stageCleared: engine.play(.stageClear)
            case .stageStarted: engine.play(.credit)
            case .gameOver: engine.play(.death)
            case .hazardSpawned: break
            }
        }
    }

    public func update(phase: GamePhase) {
        let wanted: Theme
        switch phase {
        case .attract, .gameOver: wanted = .attract
        case .ready, .playing, .dying, .stageClear: wanted = .climb
        }
        guard wanted != currentTheme else { return }
        currentTheme = wanted
        applyMusicSetting()
    }

    private func applyMusicSetting() {
        guard let engine, engine.isRunning else { return }
        engine.musicVolume = isMusicEnabled ? musicVolume : 0
        guard isMusicEnabled else {
            engine.stopMusic()
            return
        }
        switch currentTheme {
        case .none: engine.stopMusic()
        case .attract: engine.playMusic(.attract)
        case .climb: engine.playMusic(.climb)
        }
    }
}
