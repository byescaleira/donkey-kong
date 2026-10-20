import ArcadeCore
import SpriteKit
import Testing

@testable import ArcadeScene

@Suite("Transient effects")
@MainActor
struct EffectLifetimeTests {
    private func makeScene() -> SpireScene {
        let scene = SpireScene(size: VirtualViewport.coreSize.cgSize)
        scene.apply(viewport: VirtualViewport(pointSize: Vector2(x: 600, y: 700)))
        var world = GameWorld()
        world.startGame()
        scene.sync(world: world)
        return scene
    }

    private func advance(_ scene: SpireScene, seconds: Double) {
        var remaining = seconds
        while remaining > 0 {
            scene.advance(dt: 1.0 / 60)
            remaining -= 1.0 / 60
        }
    }

    @Test("a score popup disappears on its own")
    func popupExpires() {
        let scene = makeScene()
        let before = scene.activeEffectCount
        scene.emitScorePopup(points: 100, at: Vector2(x: 100, y: 100))
        #expect(scene.activeEffectCount == before + 1)
        advance(scene, seconds: 2)
        #expect(scene.activeEffectCount == before, "the popup never left the scene")
    }

    @Test("a burst disappears on its own")
    func burstExpires() {
        let scene = makeScene()
        let before = scene.activeEffectCount
        scene.emitBurst(at: Vector2(x: 100, y: 100), color: ArcadePalette.accent)
        #expect(scene.activeEffectCount > before)
        advance(scene, seconds: 2)
        #expect(scene.activeEffectCount == before, "burst shards never left the scene")
    }

    @Test("many popups do not pile up")
    func popupsDoNotAccumulate() {
        let scene = makeScene()
        for index in 0..<40 {
            scene.emitScorePopup(points: 100, at: Vector2(x: Double(index) * 4, y: 60))
        }
        advance(scene, seconds: 3)
        #expect(scene.activeEffectCount == 0, "\(scene.activeEffectCount) effects were left behind")
    }
}

@Suite("Effect safety net")
@MainActor
struct EffectSafetyTests {
    private func makeScene() -> SpireScene {
        let scene = SpireScene(size: VirtualViewport.coreSize.cgSize)
        scene.apply(viewport: VirtualViewport(pointSize: Vector2(x: 600, y: 700)))
        var world = GameWorld()
        world.startGame()
        scene.sync(world: world)
        return scene
    }

    @Test("effects never grow without bound even if nothing advances")
    func effectsAreCapped() {
        let scene = makeScene()
        for index in 0..<400 {
            scene.emitScorePopup(points: 100, at: Vector2(x: Double(index % 200), y: 60))
        }
        #expect(scene.activeEffectCount <= SpireScene.effectLimit)
    }

    @Test("changing stage clears whatever was still on screen")
    func stageChangeClearsEffects() {
        let scene = makeScene()
        for _ in 0..<10 {
            scene.emitScorePopup(points: 100, at: Vector2(x: 80, y: 80))
        }
        #expect(scene.activeEffectCount > 0)
        var next = GameWorld()
        next.begin(stage: 2)
        scene.sync(world: next)
        #expect(scene.activeEffectCount == 0, "effects survived a stage change")
    }

    @Test("a frame with no elapsed time changes nothing")
    func zeroDeltaIsSafe() {
        let scene = makeScene()
        scene.emitScorePopup(points: 100, at: Vector2(x: 60, y: 60))
        let before = scene.activeEffectCount
        scene.advance(dt: 0)
        #expect(scene.activeEffectCount == before)
    }
}
