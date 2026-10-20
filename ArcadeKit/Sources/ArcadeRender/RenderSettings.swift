import Foundation

public enum UpscalingMode: String, CaseIterable, Sendable, Identifiable {
    case off
    case quality
    case balanced
    case performance

    public var id: String { rawValue }

    public var renderScale: Double {
        switch self {
        case .off: 1
        case .quality: 1 / 1.5
        case .balanced: 1 / 1.7
        case .performance: 1 / 2
        }
    }

    public var title: String {
        switch self {
        case .off: "Native"
        case .quality: "Quality"
        case .balanced: "Balanced"
        case .performance: "Performance"
        }
    }

    public var usesMetalFX: Bool { self != .off }
}

public struct CRTSettings: Hashable, Sendable {
    public var isEnabled: Bool
    public var scanlineStrength: Double
    public var vignette: Double
    public var aberration: Double
    public var curvature: Double
    public var bloom: Double
    public var sharpen: Double

    public init(
        isEnabled: Bool = true, scanlineStrength: Double = 0.18, vignette: Double = 0.22,
        aberration: Double = 0.0012, curvature: Double = 0.012, bloom: Double = 0.35,
        sharpen: Double = 0.55
    ) {
        self.isEnabled = isEnabled
        self.scanlineStrength = scanlineStrength
        self.vignette = vignette
        self.aberration = aberration
        self.curvature = curvature
        self.bloom = bloom
        self.sharpen = sharpen
    }

    public static let modern = CRTSettings(
        isEnabled: true, scanlineStrength: 0.1, vignette: 0.14, aberration: 0, curvature: 0,
        bloom: 0.28, sharpen: 0.5)

    public static let off = CRTSettings(
        isEnabled: false, scanlineStrength: 0, vignette: 0, aberration: 0, curvature: 0, bloom: 0,
        sharpen: 0.5)
}

public struct RenderSettings: Hashable, Sendable {
    public static let fourKHeight = 2160

    public var upscaling: UpscalingMode
    public var crt: CRTSettings
    public var maxOutputHeight: Int
    public var framesPerSecond: Int

    public init(
        upscaling: UpscalingMode = .quality, crt: CRTSettings = CRTSettings(),
        maxOutputHeight: Int = RenderSettings.fourKHeight, framesPerSecond: Int = 60
    ) {
        self.upscaling = upscaling
        self.crt = crt
        self.maxOutputHeight = maxOutputHeight
        self.framesPerSecond = framesPerSecond
    }

    public func outputSize(forDrawable drawable: Vector2Int) -> Vector2Int {
        guard drawable.y > maxOutputHeight, drawable.y > 0 else { return drawable }
        let ratio = Double(maxOutputHeight) / Double(drawable.y)
        return Vector2Int(
            x: max(Int((Double(drawable.x) * ratio).rounded()), 1), y: maxOutputHeight)
    }

    public func renderSize(forOutput output: Vector2Int) -> Vector2Int {
        let scale = upscaling.renderScale
        guard scale < 0.999 else { return output }
        return Vector2Int(
            x: max(Int((Double(output.x) * scale).rounded()), 1),
            y: max(Int((Double(output.y) * scale).rounded()), 1))
    }
}

public struct Vector2Int: Hashable, Sendable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public var isEmpty: Bool { x <= 0 || y <= 0 }
}
