import Foundation

public struct PixelColor: Hashable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255, alpha: alpha)
    }

    public static let clear = PixelColor(red: 0, green: 0, blue: 0, alpha: 0)
}

public enum ArcadePalette {
    public static let clear = PixelColor.clear
    public static let shell = PixelColor(hex: 0x3F_C9_BE)
    public static let shellDark = PixelColor(hex: 0x1E_7F_7A)
    public static let visor = PixelColor(hex: 0xFF_B3_3C)
    public static let metal = PixelColor(hex: 0xA8_B4_C0)
    public static let accent = PixelColor(hex: 0xFF_6A_3C)
    public static let outline = PixelColor(hex: 0x14_18_26)
    public static let highlight = PixelColor(hex: 0xFF_FF_F4)
    public static let rust = PixelColor(hex: 0xC2_4E_32)
    public static let signal = PixelColor(hex: 0xFF_E0_4A)

    public static let girder = PixelColor(hex: 0xE8_5C_3A)
    public static let girderShade = PixelColor(hex: 0x9E_33_1F)
    public static let ladder = PixelColor(hex: 0x6E_D9_F0)
    public static let ladderBroken = PixelColor(hex: 0x3A_7A_8C)
    public static let background = PixelColor(hex: 0x06_07_0E)
    public static let backgroundFar = PixelColor(hex: 0x10_12_22)

    public static let indexed: [PixelColor] = [
        clear, shell, shellDark, visor, metal, accent, outline, highlight, rust, signal,
    ]
}

public struct PixelSprite: Sendable, Hashable {
    public let width: Int
    public let height: Int
    public let indices: [UInt8]

    public init(width: Int, height: Int, indices: [UInt8]) {
        self.width = width
        self.height = height
        self.indices = indices
    }

    public init(rows: [String]) {
        let height = rows.count
        let width = rows.map(\.count).max() ?? 0
        var indices = [UInt8](repeating: 0, count: width * height)
        for (row, line) in rows.enumerated() {
            for (column, character) in line.enumerated() where column < width {
                indices[row * width + column] = Self.index(for: character)
            }
        }
        self.width = width
        self.height = height
        self.indices = indices
    }

    private static func index(for character: Character) -> UInt8 {
        guard let value = character.wholeNumberValue, value >= 0, value < ArcadePalette.indexed.count
        else { return 0 }
        return UInt8(value)
    }

    public func color(x: Int, y: Int) -> PixelColor {
        guard x >= 0, x < width, y >= 0, y < height else { return .clear }
        let index = Int(indices[y * width + x])
        guard index < ArcadePalette.indexed.count else { return .clear }
        return ArcadePalette.indexed[index]
    }

    public var isEmpty: Bool { width == 0 || height == 0 }

    public func rgbaBytes() -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let pixel = color(x: x, y: y)
                let offset = (y * width + x) * 4
                let alpha = pixel.alpha
                bytes[offset] = UInt8((pixel.red * alpha * 255).rounded())
                bytes[offset + 1] = UInt8((pixel.green * alpha * 255).rounded())
                bytes[offset + 2] = UInt8((pixel.blue * alpha * 255).rounded())
                bytes[offset + 3] = UInt8((alpha * 255).rounded())
            }
        }
        return bytes
    }

    public func flippedHorizontally() -> PixelSprite {
        var flipped = [UInt8](repeating: 0, count: indices.count)
        for y in 0..<height {
            for x in 0..<width {
                flipped[y * width + x] = indices[y * width + (width - 1 - x)]
            }
        }
        return PixelSprite(width: width, height: height, indices: flipped)
    }
}
