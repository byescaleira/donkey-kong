import CoreGraphics

public enum HUDMetrics {
    #if os(tvOS)
        public static let scale: CGFloat = 2.0
        public static let margin: CGFloat = 48
    #else
        public static let scale: CGFloat = 1
        public static let margin: CGFloat = 16
    #endif

    public static func size(_ base: CGFloat) -> CGFloat {
        base * scale
    }
}
