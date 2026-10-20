import Testing

@testable import ArcadeCore

@Suite("Pixel art")
struct SpriteTests {
    @Test("every sprite is a complete rectangle with no ragged rows", arguments: SpriteName.allCases)
    func spritesAreRectangular(name: SpriteName) {
        let sprite = ArcadeSprites.sprite(name)
        #expect(sprite.width > 0)
        #expect(sprite.height > 0)
        #expect(sprite.indices.count == sprite.width * sprite.height)
    }

    @Test("every sprite index maps to a real palette entry", arguments: SpriteName.allCases)
    func spriteIndicesAreInPalette(name: SpriteName) {
        let sprite = ArcadeSprites.sprite(name)
        for index in sprite.indices {
            #expect(Int(index) < ArcadePalette.indexed.count)
        }
    }

    @Test("every sprite has visible pixels", arguments: SpriteName.allCases)
    func spritesAreNotBlank(name: SpriteName) {
        let sprite = ArcadeSprites.sprite(name)
        #expect(sprite.indices.contains { $0 != 0 })
    }

    @Test("flipping twice returns the original sprite")
    func flipIsReversible() {
        let sprite = ArcadeSprites.pipStand
        #expect(sprite.flippedHorizontally().flippedHorizontally() == sprite)
    }

    @Test("flipping mirrors columns")
    func flipMirrorsColumns() {
        let sprite = PixelSprite(rows: ["16", "61"])
        let flipped = sprite.flippedHorizontally()
        #expect(flipped.color(x: 0, y: 0) == ArcadePalette.outline)
        #expect(flipped.color(x: 1, y: 0) == ArcadePalette.shell)
    }

    @Test("rgba bytes are premultiplied and sized for the sprite")
    func rgbaBytesAreWellFormed() {
        let sprite = ArcadeSprites.canister
        let bytes = sprite.rgbaBytes()
        #expect(bytes.count == sprite.width * sprite.height * 4)
        for offset in stride(from: 0, to: bytes.count, by: 4) {
            #expect(bytes[offset] <= bytes[offset + 3])
            #expect(bytes[offset + 1] <= bytes[offset + 3])
            #expect(bytes[offset + 2] <= bytes[offset + 3])
        }
    }

    @Test("transparent pixels stay fully transparent")
    func clearPixelsAreTransparent() {
        let sprite = PixelSprite(rows: [".."])
        #expect(sprite.rgbaBytes().allSatisfy { $0 == 0 })
    }

    @Test("out of bounds reads are transparent instead of trapping")
    func outOfBoundsIsClear() {
        let sprite = ArcadeSprites.chip
        #expect(sprite.color(x: -1, y: 0) == .clear)
        #expect(sprite.color(x: sprite.width, y: 0) == .clear)
        #expect(sprite.color(x: 0, y: sprite.height) == .clear)
    }
}

@Suite("Deterministic randomness")
struct RandomTests {
    @Test("the same seed gives the same sequence")
    func seedsAreReproducible() {
        var first = GameRandom(seed: 7)
        var second = GameRandom(seed: 7)
        for _ in 0..<50 {
            #expect(first.next() == second.next())
        }
    }

    @Test("different seeds diverge")
    func seedsDiverge() {
        var first = GameRandom(seed: 1)
        var second = GameRandom(seed: 2)
        #expect(first.next() != second.next())
    }

    @Test("unit values stay inside zero and one")
    func unitIsNormalized() {
        var random = GameRandom(seed: 99)
        for _ in 0..<500 {
            let value = random.unit()
            #expect(value >= 0)
            #expect(value < 1)
        }
    }

    @Test("ranged values stay inside their bounds")
    func rangeIsRespected() {
        var random = GameRandom(seed: 123)
        for _ in 0..<500 {
            let value = random.range(10...20)
            #expect(value >= 10)
            #expect(value <= 20)
        }
    }

    @Test("a zero seed still produces a usable generator")
    func zeroSeedIsSafe() {
        var random = GameRandom(seed: 0)
        #expect(random.next() != 0)
    }
}
