import Testing

@testable import ArcadeCore

@Suite("Responsive viewport")
struct ViewportTests {
    @Test(
        "the core play area always fits on screen",
        arguments: [
            Vector2(x: 1179, y: 2556),
            Vector2(x: 2556, y: 1179),
            Vector2(x: 2048, y: 2732),
            Vector2(x: 3840, y: 2160),
            Vector2(x: 1280, y: 800),
            Vector2(x: 5120, y: 1440),
        ])
    func coreAlwaysFits(size: Vector2) {
        let viewport = VirtualViewport(pointSize: size)
        #expect(viewport.visibleSize.x >= viewport.coreSize.x - 0.001)
        #expect(viewport.visibleSize.y >= viewport.coreSize.y - 0.001)
        #expect(viewport.scale > 0)
    }

    @Test("the visible area keeps the screen aspect ratio so nothing is letterboxed")
    func visibleAreaMatchesScreenAspect() {
        let size = Vector2(x: 2556, y: 1179)
        let viewport = VirtualViewport(pointSize: size)
        let screenAspect = size.x / size.y
        let visibleAspect = viewport.visibleSize.x / viewport.visibleSize.y
        #expect(abs(screenAspect - visibleAspect) < 0.0001)
    }

    @Test("a wide screen gains horizontal playfield instead of black bars")
    func wideScreenExtendsHorizontally() {
        let viewport = VirtualViewport(pointSize: Vector2(x: 2556, y: 1179))
        #expect(viewport.extraWidth > 0)
        #expect(abs(viewport.extraHeight) < 0.001)
    }

    @Test("a tall screen gains vertical playfield instead of black bars")
    func tallScreenExtendsVertically() {
        let viewport = VirtualViewport(pointSize: Vector2(x: 1179, y: 2556))
        #expect(viewport.extraHeight > 0)
        #expect(abs(viewport.extraWidth) < 0.001)
    }

    @Test("the core area is centred inside the safe area, not the raw screen")
    func coreRespectsSafeArea() {
        let size = Vector2(x: 1179, y: 2556)
        let insets = EdgeInsets2(top: 120, leading: 0, bottom: 60, trailing: 0)
        let plain = VirtualViewport(pointSize: size)
        let inset = VirtualViewport(pointSize: size, safeArea: insets)
        #expect(inset.coreRect.midY < plain.coreRect.midY)
        #expect(inset.scale <= plain.scale)
    }

    @Test("scene points are offset by the core origin")
    func scenePointsAreOffset() {
        let viewport = VirtualViewport(pointSize: Vector2(x: 2556, y: 1179))
        let mapped = viewport.scenePoint(Vector2(x: 0, y: 0))
        #expect(abs(mapped.x - viewport.coreRect.minX) < 0.001)
        #expect(abs(mapped.y - viewport.coreRect.minY) < 0.001)
    }

    @Test("a degenerate size does not divide by zero")
    func degenerateSizeIsSafe() {
        let viewport = VirtualViewport(pointSize: Vector2(x: 0, y: 0))
        #expect(viewport.scale > 0)
        #expect(viewport.visibleSize.x.isFinite)
        #expect(viewport.visibleSize.y.isFinite)
    }
}

@Suite("Fixed timestep clock")
struct GameClockTests {
    @Test("the first frame produces no steps because there is no delta yet")
    func firstFrameHasNoSteps() {
        var clock = GameClock()
        #expect(clock.advance(to: 0) == 0)
    }

    @Test("one sixtieth of a second produces exactly one step")
    func oneTickPerFrameAt60Hz() {
        var clock = GameClock()
        _ = clock.advance(to: 0)
        #expect(clock.advance(to: GameClock.tickDuration) == 1)
        #expect(clock.tick == 1)
    }

    @Test("a 120 Hz display still advances the simulation at 60 Hz")
    func highRefreshDisplayKeepsSimulationRate() {
        var clock = GameClock()
        var time = 0.0
        _ = clock.advance(to: time)
        var steps = 0
        for _ in 0..<120 {
            time += 1.0 / 120
            steps += clock.advance(to: time)
        }
        #expect(steps == 60)
    }

    @Test("a long stall is clamped so the simulation never spirals")
    func longStallIsClamped() {
        var clock = GameClock()
        _ = clock.advance(to: 0)
        let steps = clock.advance(to: 10)
        #expect(steps == GameClock.maxStepsPerFrame)
    }

    @Test("reset drops the pending delta")
    func resetDropsDelta() {
        var clock = GameClock()
        _ = clock.advance(to: 0)
        clock.reset()
        #expect(clock.advance(to: 5) == 0)
    }
}
