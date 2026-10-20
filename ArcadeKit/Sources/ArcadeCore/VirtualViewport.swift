import Foundation

public struct EdgeInsets2: Hashable, Sendable {
    public var top: Double
    public var leading: Double
    public var bottom: Double
    public var trailing: Double

    public init(top: Double = 0, leading: Double = 0, bottom: Double = 0, trailing: Double = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    public static let zero = EdgeInsets2()
}

public struct VirtualViewport: Equatable, Sendable {
    public static let coreSize = Vector2(x: 224, y: 256)

    public let pointSize: Vector2
    public let safeArea: EdgeInsets2
    public let coreSize: Vector2
    public let scale: Double
    public let visibleSize: Vector2
    public let coreRect: Rect

    public init(
        pointSize: Vector2, safeArea: EdgeInsets2 = .zero, coreSize: Vector2 = VirtualViewport.coreSize
    ) {
        let width = max(pointSize.x, 1)
        let height = max(pointSize.y, 1)
        self.pointSize = Vector2(x: width, y: height)
        self.safeArea = safeArea
        self.coreSize = coreSize

        let safeWidth = max(width - safeArea.leading - safeArea.trailing, 1)
        let safeHeight = max(height - safeArea.top - safeArea.bottom, 1)
        let fitted = min(safeWidth / coreSize.x, safeHeight / coreSize.y)
        scale = fitted
        visibleSize = Vector2(x: width / fitted, y: height / fitted)

        let safeCenter = Vector2(
            x: (safeArea.leading + (width - safeArea.trailing)) / 2 / fitted,
            y: (safeArea.bottom + (height - safeArea.top)) / 2 / fitted)
        coreRect = Rect.centered(at: safeCenter, size: coreSize)
    }

    public var extraWidth: Double { visibleSize.x - coreSize.x }
    public var extraHeight: Double { visibleSize.y - coreSize.y }

    public func scenePoint(_ virtual: Vector2) -> Vector2 {
        Vector2(x: coreRect.minX + virtual.x, y: coreRect.minY + virtual.y)
    }
}
