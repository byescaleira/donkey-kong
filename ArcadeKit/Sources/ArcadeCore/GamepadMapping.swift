import Foundation

public struct GamepadReading: Hashable, Sendable {
    public var horizontal: Double
    public var vertical: Double
    public var isJumpPressed: Bool

    public init(horizontal: Double = 0, vertical: Double = 0, isJumpPressed: Bool = false) {
        self.horizontal = horizontal
        self.vertical = vertical
        self.isJumpPressed = isJumpPressed
    }

    public static let idle = GamepadReading()
}

public struct GamepadCommand: Hashable, Sendable {
    public var horizontal: Double
    public var vertical: Double
    public var pressesJump: Bool
    public var releasesJump: Bool
    public var pressesStart: Bool

    public static let idle = GamepadCommand(
        horizontal: 0, vertical: 0, pressesJump: false, releasesJump: false, pressesStart: false)
}

public struct GamepadMapping: Sendable {
    public static let deadzone = 0.18

    private var wasJumpPressed = false

    public init() {}

    public mutating func apply(_ reading: GamepadReading) -> GamepadCommand {
        let command = GamepadCommand(
            horizontal: Self.filter(reading.horizontal),
            vertical: Self.filter(reading.vertical),
            pressesJump: reading.isJumpPressed && !wasJumpPressed,
            releasesJump: !reading.isJumpPressed && wasJumpPressed,
            pressesStart: reading.isJumpPressed && !wasJumpPressed)
        wasJumpPressed = reading.isJumpPressed
        return command
    }

    public mutating func disconnect() {
        wasJumpPressed = false
    }

    public static func filter(_ value: Double) -> Double {
        let clamped = value.clamped(to: -1...1)
        return abs(clamped) < deadzone ? 0 : clamped
    }
}

extension InputBuffer {
    public func apply(_ command: GamepadCommand) {
        setAxes(horizontal: command.horizontal, vertical: command.vertical)
        if command.pressesJump {
            pressJump()
            pressStart()
        } else if command.releasesJump {
            releaseJump()
        }
    }
}
