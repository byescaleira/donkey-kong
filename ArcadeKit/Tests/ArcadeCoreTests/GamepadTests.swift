import Testing

@testable import ArcadeCore

@Suite("Controller mapping")
struct GamepadTests {
    @Test("a resting stick reads as no movement")
    func deadzoneSwallowsDrift() {
        #expect(GamepadMapping.filter(0.1) == 0)
        #expect(GamepadMapping.filter(-0.1) == 0)
        #expect(GamepadMapping.filter(0) == 0)
    }

    @Test("a deliberate push passes through unchanged")
    func pushPassesThrough() {
        #expect(GamepadMapping.filter(0.75) == 0.75)
        #expect(GamepadMapping.filter(-0.75) == -0.75)
    }

    @Test("combined stick and d-pad values cannot exceed full tilt")
    func combinedAxesAreClamped() {
        #expect(GamepadMapping.filter(1.9) == 1)
        #expect(GamepadMapping.filter(-1.9) == -1)
    }

    @Test("holding the jump button fires exactly one jump")
    func jumpFiresOncePerPress() {
        var mapping = GamepadMapping()
        let held = GamepadReading(isJumpPressed: true)
        let first = mapping.apply(held)
        #expect(first.pressesJump)
        for _ in 0..<30 {
            #expect(!mapping.apply(held).pressesJump)
        }
    }

    @Test("releasing the button reports a release exactly once")
    func releaseFiresOnce() {
        var mapping = GamepadMapping()
        _ = mapping.apply(GamepadReading(isJumpPressed: true))
        let release = mapping.apply(.idle)
        #expect(release.releasesJump)
        #expect(!mapping.apply(.idle).releasesJump)
    }

    @Test("pressing again after a release jumps again")
    func jumpRearms() {
        var mapping = GamepadMapping()
        _ = mapping.apply(GamepadReading(isJumpPressed: true))
        _ = mapping.apply(.idle)
        #expect(mapping.apply(GamepadReading(isJumpPressed: true)).pressesJump)
    }

    @Test("any button press also counts as inserting a credit")
    func anyButtonStarts() {
        var mapping = GamepadMapping()
        #expect(mapping.apply(GamepadReading(isJumpPressed: true)).pressesStart)
    }

    @Test("a disconnect rearms the button so a reconnect is not swallowed")
    func disconnectRearms() {
        var mapping = GamepadMapping()
        _ = mapping.apply(GamepadReading(isJumpPressed: true))
        mapping.disconnect()
        #expect(mapping.apply(GamepadReading(isJumpPressed: true)).pressesJump)
    }

    @Test("an idle controller produces no commands at all")
    func idleIsQuiet() {
        var mapping = GamepadMapping()
        let command = mapping.apply(.idle)
        #expect(command == .idle)
    }

    @Test("the mapping drives the shared input buffer")
    @MainActor
    func mappingFeedsTheBuffer() {
        var mapping = GamepadMapping()
        let buffer = InputBuffer()
        buffer.apply(mapping.apply(GamepadReading(horizontal: -0.9, isJumpPressed: true)))
        let state = buffer.consume()
        #expect(state.horizontal == -0.9)
        #expect(state.jump)
        #expect(state.start)
    }

    @Test("drift on the stick does not nudge the climber")
    @MainActor
    func driftDoesNotMove() {
        var mapping = GamepadMapping()
        let buffer = InputBuffer()
        buffer.apply(mapping.apply(GamepadReading(horizontal: 0.08, vertical: -0.12)))
        let state = buffer.consume()
        #expect(state.horizontal == 0)
        #expect(state.vertical == 0)
    }
}
