import ArcadeCore
import SpriteKit

public final class SpireScene: SKScene {
    private let worldLayer = SKNode()
    private let backgroundLayer = SKNode()
    private let structureLayer = SKNode()
    private let actorLayer = SKNode()
    private let effectLayer = SKNode()

    private var hazardNodes: [Int: SKSpriteNode] = [:]
    private var climberNode: SKSpriteNode?
    private var pickupNode: SKSpriteNode?
    private var prizeNode: SKSpriteNode?
    private var craneNode: CraneNode?

    private let sceneryLayer = SKNode()
    private var viewport: VirtualViewport?
    private var structureKey: String?
    private var currentLevel: LevelLayout?

    public override init(size: CGSize) {
        super.init(size: size)
        anchorPoint = .zero
        scaleMode = .fill
        backgroundColor = ArcadePalette.background.skColor
        addChild(backgroundLayer)
        backgroundLayer.addChild(sceneryLayer)
        addChild(worldLayer)
        worldLayer.addChild(structureLayer)
        worldLayer.addChild(actorLayer)
        worldLayer.addChild(effectLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("SpireScene is created in code")
    }

    public func apply(viewport: VirtualViewport) {
        guard self.viewport != viewport else { return }
        self.viewport = viewport
        size = viewport.visibleSize.cgSize
        worldLayer.position = CGPoint(x: viewport.coreRect.minX, y: viewport.coreRect.minY)
        rebuildBackground(viewport: viewport)
        if let currentLevel {
            rebuildScenery(viewport: viewport, level: currentLevel)
        }
    }

    public func sync(world: GameWorld) {
        let key = "\(world.level.stage)-\(world.level.girders.count)-\(world.level.ladders.count)"
        if structureKey != key {
            structureKey = key
            currentLevel = world.level
            rebuildStructure(level: world.level)
            if let viewport {
                rebuildScenery(viewport: viewport, level: world.level)
            }
        }
        syncClimber(world.climber, phase: world.phase)
        syncHazards(world.hazards)
        syncPickup(world.overclock)
        craneNode?.update(time: world.climber.animationTime, isActive: world.phase.isInteractive)
    }

    public func emitScorePopup(points: Int, at position: Vector2) {
        let label = SKLabelNode(text: "\(points)")
        label.fontName = "Menlo-Bold"
        label.fontSize = 9
        label.fontColor = ArcadePalette.signal.skColor
        label.position = CGPoint(x: position.x, y: position.y + 18)
        label.zPosition = 50
        effectLayer.addChild(label)
        label.run(
            .sequence([
                .group([.moveBy(x: 0, y: 16, duration: 0.7), .fadeOut(withDuration: 0.7)]),
                .removeFromParent(),
            ]))
    }

    public func emitBurst(at position: Vector2, color: PixelColor) {
        for index in 0..<8 {
            let shard = SKSpriteNode(color: color.skColor, size: CGSize(width: 2, height: 2))
            shard.position = position.cgPoint
            shard.zPosition = 45
            effectLayer.addChild(shard)
            let angle = Double(index) / 8 * .pi * 2
            shard.run(
                .sequence([
                    .group([
                        .moveBy(x: cos(angle) * 16, y: sin(angle) * 16 + 6, duration: 0.4),
                        .fadeOut(withDuration: 0.4),
                    ]),
                    .removeFromParent(),
                ]))
        }
    }

    private func rebuildBackground(viewport: VirtualViewport) {
        backgroundLayer.removeAllChildren()
        let backdrop = SKSpriteNode(
            color: ArcadePalette.background.skColor, size: viewport.visibleSize.cgSize)
        backdrop.anchorPoint = .zero
        backdrop.zPosition = -100
        backgroundLayer.addChild(backdrop)

        let haze = SKSpriteNode(
            texture: TextureFactory.shared.verticalGradient(
                from: ArcadePalette.background, to: ArcadePalette.backgroundFar),
            size: viewport.visibleSize.cgSize)
        haze.anchorPoint = .zero
        haze.zPosition = -99
        backgroundLayer.addChild(haze)

        var random = GameRandom(seed: 0x5EED_1234)
        for _ in 0..<110 {
            let size = random.chance(0.18) ? 2.0 : 1.0
            let mote = SKSpriteNode(
                color: ArcadePalette.metal.skColor, size: CGSize(width: size, height: size))
            mote.position = CGPoint(
                x: random.range(0...viewport.visibleSize.x),
                y: random.range(0...viewport.visibleSize.y))
            mote.alpha = random.range(0.07...0.3)
            mote.zPosition = -98
            backgroundLayer.addChild(mote)
        }
    }

    private func rebuildScenery(viewport: VirtualViewport, level: LevelLayout) {
        sceneryLayer.removeAllChildren()
        sceneryLayer.zPosition = -90
        guard viewport.extraWidth > 2 else { return }

        let originX = viewport.coreRect.minX
        let originY = viewport.coreRect.minY
        for girder in level.girders {
            let midY = originY + (girder.start.y + girder.end.y) / 2
            let strut = SKSpriteNode(
                color: ArcadePalette.girderShade.skColor,
                size: CGSize(width: viewport.visibleSize.x, height: 3))
            strut.position = CGPoint(x: viewport.visibleSize.x / 2, y: midY)
            strut.alpha = 0.22
            sceneryLayer.addChild(strut)
        }

        let columnInset: Double = 18
        for side in [originX - columnInset, originX + level.topGirder.maxX + columnInset] {
            guard side > 2, side < viewport.visibleSize.x - 2 else { continue }
            let column = SKSpriteNode(
                color: ArcadePalette.metal.skColor,
                size: CGSize(width: 4, height: viewport.visibleSize.y))
            column.position = CGPoint(x: side, y: viewport.visibleSize.y / 2)
            column.alpha = 0.14
            sceneryLayer.addChild(column)
        }
    }

    private func rebuildStructure(level: LevelLayout) {
        structureLayer.removeAllChildren()
        for ladder in level.ladders {
            structureLayer.addChild(LadderNode(ladder: ladder))
        }
        for girder in level.girders {
            structureLayer.addChild(GirderNode(girder: girder))
        }

        let prize = SKSpriteNode(texture: TextureFactory.shared.texture(.core))
        prize.position = level.prizePosition.cgPoint
        prize.zPosition = 10
        prize.run(
            .repeatForever(
                .sequence([.moveBy(x: 0, y: 2, duration: 0.9), .moveBy(x: 0, y: -2, duration: 0.9)])))
        structureLayer.addChild(prize)
        prizeNode = prize

        let crane = CraneNode()
        crane.position = level.cranePosition.cgPoint
        crane.zPosition = 9
        structureLayer.addChild(crane)
        craneNode = crane
    }

    private func syncClimber(_ climber: Climber, phase: GamePhase) {
        let node = climberNode ?? makeClimberNode()
        node.position = CGPoint(x: climber.position.x, y: climber.position.y + ClimberMotion.size.y / 2)
        node.texture = TextureFactory.shared.texture(
            climberSprite(climber), flipped: climber.facing == .left && !isClimbing(climber))
        node.isHidden = {
            if case .attract = phase { return true }
            return false
        }()
        node.alpha = climber.hasOverclock ? (sin(climber.animationTime * 18) > 0 ? 1 : 0.55) : 1
    }

    private func isClimbing(_ climber: Climber) -> Bool {
        if case .climbing = climber.state { return true }
        return false
    }

    private func climberSprite(_ climber: Climber) -> SpriteName {
        switch climber.state {
        case .dying: .pipHurt
        case .airborne: .pipJump
        case .climbing:
            Int(climber.position.y / 6) % 2 == 0 ? .pipClimbA : .pipClimbB
        case .grounded:
            if abs(climber.velocity.x) < 0.5 { .pipStand }
            else { Int(climber.animationTime * 9) % 2 == 0 ? .pipWalkA : .pipWalkB }
        }
    }

    private func makeClimberNode() -> SKSpriteNode {
        let node = SKSpriteNode(texture: TextureFactory.shared.texture(.pipStand))
        node.zPosition = 30
        actorLayer.addChild(node)
        climberNode = node
        return node
    }

    private func syncHazards(_ hazards: [Hazard]) {
        var seen = Set<Int>()
        for hazard in hazards {
            seen.insert(hazard.id)
            let node: SKSpriteNode
            if let existing = hazardNodes[hazard.id] {
                node = existing
            } else {
                node = SKSpriteNode(texture: TextureFactory.shared.texture(.canister))
                node.zPosition = 25
                actorLayer.addChild(node)
                hazardNodes[hazard.id] = node
            }
            node.position = CGPoint(x: hazard.position.x, y: hazard.position.y + Hazard.size.y / 2)
            node.zRotation = CGFloat(-hazard.spin)
            if case .smashed(let elapsed) = hazard.state {
                node.alpha = CGFloat(1 - elapsed / Hazard.smashDuration)
                node.setScale(CGFloat(1 + elapsed * 1.5))
            }
        }
        for (id, node) in hazardNodes where !seen.contains(id) {
            node.removeFromParent()
            hazardNodes[id] = nil
        }
    }

    private func syncPickup(_ pickup: GameWorld.Pickup?) {
        guard let pickup else {
            pickupNode?.removeFromParent()
            pickupNode = nil
            return
        }
        let node = pickupNode ?? makePickupNode()
        node.position = CGPoint(x: pickup.position.x, y: pickup.position.y + 6)
        node.isHidden = pickup.isCollected
    }

    private func makePickupNode() -> SKSpriteNode {
        let node = SKSpriteNode(texture: TextureFactory.shared.texture(.chip))
        node.zPosition = 20
        node.run(
            .repeatForever(
                .sequence([
                    .fadeAlpha(to: 0.6, duration: 0.5), .fadeAlpha(to: 1, duration: 0.5),
                ])))
        actorLayer.addChild(node)
        pickupNode = node
        return node
    }
}
