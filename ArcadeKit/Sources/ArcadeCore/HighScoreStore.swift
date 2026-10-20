import Foundation

public protocol HighScoreStoring: Sendable {
    func load() -> Int
    func save(_ value: Int)
}

public struct UserDefaultsHighScore: HighScoreStoring, @unchecked Sendable {
    public static let key = "scrapspire.highScore"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> Int {
        max(defaults.integer(forKey: Self.key), 0)
    }

    public func save(_ value: Int) {
        guard value > load() else { return }
        defaults.set(value, forKey: Self.key)
    }
}

public struct MemoryHighScore: HighScoreStoring {
    private final class Box: @unchecked Sendable {
        var value = 0
    }

    private let box = Box()

    public init(initial: Int = 0) {
        box.value = initial
    }

    public func load() -> Int { box.value }

    public func save(_ value: Int) {
        if value > box.value { box.value = value }
    }
}
