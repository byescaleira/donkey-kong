import Foundation

public struct InputState: Hashable, Sendable {
    public var horizontal: Double
    public var vertical: Double
    public var jump: Bool
    public var start: Bool

    public init(horizontal: Double = 0, vertical: Double = 0, jump: Bool = false, start: Bool = false) {
        self.horizontal = horizontal
        self.vertical = vertical
        self.jump = jump
        self.start = start
    }

    public static let neutral = InputState()

    public var isPressingUp: Bool { vertical > 0.35 }
    public var isPressingDown: Bool { vertical < -0.35 }

    public func normalized() -> InputState {
        InputState(
            horizontal: horizontal.clamped(to: -1...1), vertical: vertical.clamped(to: -1...1),
            jump: jump, start: start)
    }
}

@MainActor
public final class InputBuffer {
    private var current = InputState()
    private var jumpLatched = false
    private var startLatched = false

    public init() {}

    public func setAxes(horizontal: Double, vertical: Double) {
        current.horizontal = horizontal
        current.vertical = vertical
    }

    public func setHorizontal(_ value: Double) {
        current.horizontal = value
    }

    public func setVertical(_ value: Double) {
        current.vertical = value
    }

    public func pressJump() {
        jumpLatched = true
        current.jump = true
    }

    public func releaseJump() {
        current.jump = false
    }

    public func pressStart() {
        startLatched = true
    }

    public func consume() -> InputState {
        var state = current.normalized()
        state.jump = current.jump || jumpLatched
        state.start = startLatched
        jumpLatched = false
        startLatched = false
        return state
    }

    public func releaseAll() {
        current = InputState()
        jumpLatched = false
        startLatched = false
    }
}
