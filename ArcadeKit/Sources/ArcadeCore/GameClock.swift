import Foundation

public struct GameClock: Sendable {
    public static let tickRate: Double = 60
    public static let tickDuration: Double = 1 / tickRate
    public static let maxStepsPerFrame = 5
    private static let epsilon = 1e-9

    public private(set) var tick: UInt64 = 0
    public private(set) var interpolation: Double = 0
    private var accumulator: Double = 0
    private var previousTime: Double?

    public init() {}

    public mutating func advance(to time: Double) -> Int {
        defer { previousTime = time }
        guard let previousTime else { return 0 }
        let elapsed = (time - previousTime).clamped(to: 0...0.25)
        accumulator += elapsed
        var steps = 0
        while accumulator >= Self.tickDuration - Self.epsilon, steps < Self.maxStepsPerFrame {
            accumulator -= Self.tickDuration
            steps += 1
        }
        if steps == Self.maxStepsPerFrame {
            accumulator = 0
        }
        tick += UInt64(steps)
        interpolation = accumulator / Self.tickDuration
        return steps
    }

    public mutating func reset() {
        previousTime = nil
        accumulator = 0
        interpolation = 0
    }
}
