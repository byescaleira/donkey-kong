import Foundation

public struct Vector2: Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let zero = Vector2(x: 0, y: 0)

    public var length: Double { (x * x + y * y).squareRoot() }

    public static func + (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    public static func - (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    public static func * (lhs: Vector2, rhs: Double) -> Vector2 {
        Vector2(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    public static func += (lhs: inout Vector2, rhs: Vector2) {
        lhs = lhs + rhs
    }
}

public struct Rect: Hashable, Sendable {
    public var origin: Vector2
    public var size: Vector2

    public init(origin: Vector2, size: Vector2) {
        self.origin = origin
        self.size = size
    }

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.init(origin: Vector2(x: x, y: y), size: Vector2(x: width, y: height))
    }

    public var minX: Double { origin.x }
    public var maxX: Double { origin.x + size.x }
    public var minY: Double { origin.y }
    public var maxY: Double { origin.y + size.y }
    public var midX: Double { origin.x + size.x / 2 }
    public var midY: Double { origin.y + size.y / 2 }
    public var center: Vector2 { Vector2(x: midX, y: midY) }

    public func intersects(_ other: Rect) -> Bool {
        minX < other.maxX && other.minX < maxX && minY < other.maxY && other.minY < maxY
    }

    public func contains(_ point: Vector2) -> Bool {
        point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
    }

    public func insetBy(dx: Double, dy: Double) -> Rect {
        Rect(x: minX + dx, y: minY + dy, width: size.x - dx * 2, height: size.y - dy * 2)
    }

    public static func centered(at point: Vector2, size: Vector2) -> Rect {
        Rect(origin: Vector2(x: point.x - size.x / 2, y: point.y - size.y / 2), size: size)
    }
}

extension Double {
    public func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }

    public func approaching(_ target: Double, by step: Double) -> Double {
        if self < target { return min(self + step, target) }
        if self > target { return max(self - step, target) }
        return self
    }
}
