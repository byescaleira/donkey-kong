import Foundation

public enum SpriteName: String, CaseIterable, Sendable {
    case pipStand
    case pipWalkA
    case pipWalkB
    case pipJump
    case pipClimbA
    case pipClimbB
    case pipHurt
    case canister
    case core
    case chip
}

public enum ArcadeSprites {
    public static func sprite(_ name: SpriteName) -> PixelSprite {
        switch name {
        case .pipStand: pipStand
        case .pipWalkA: pipWalkA
        case .pipWalkB: pipWalkB
        case .pipJump: pipJump
        case .pipClimbA: pipClimbA
        case .pipClimbB: pipClimbB
        case .pipHurt: pipHurt
        case .canister: canister
        case .core: core
        case .chip: chip
        }
    }

    private static let pipHead: [String] = [
        "....6666....",
        "...655556...",
        "..65555556..",
        "..63333336..",
        "..63777336..",
        "..63333336..",
        "..64444446..",
    ]

    public static let pipStand = PixelSprite(
        rows: pipHead + [
            "...611116...",
            "..61111116..",
            ".6111551116.",
            ".6111551116.",
            ".6111111116.",
            "..64444446..",
            "..611..116..",
            "..644..446..",
            ".6444..4446.",
        ])

    public static let pipWalkA = PixelSprite(
        rows: pipHead + [
            "...611116...",
            "..61111116..",
            ".6111551116.",
            ".6111551116.",
            ".6111111116.",
            "..64444446..",
            ".611....116.",
            "6444....4446",
            "444......444",
        ])

    public static let pipWalkB = PixelSprite(
        rows: pipHead + [
            "...611116...",
            "..61111116..",
            ".6111551116.",
            ".6111551116.",
            ".6111111116.",
            "..64444446..",
            "...611116...",
            "...644446...",
            "..6444446...",
        ])

    public static let pipJump = PixelSprite(
        rows: pipHead + [
            "...611116...",
            ".461111164..",
            ".6111551116.",
            ".6111551116.",
            ".6111111116.",
            "..64444446..",
            ".611....116.",
            "644......446",
            "44........44",
        ])

    public static let pipClimbA = PixelSprite(
        rows: pipHead + [
            ".461111164..",
            ".461111164..",
            "..61155116..",
            "..61111116..",
            "..64444446..",
            "...611116...",
            "..64....46..",
            "..44....44..",
            "............",
        ])

    public static let pipClimbB = PixelSprite(
        rows: pipHead + [
            "...611116...",
            "..61111116..",
            "..61155116..",
            ".6111111116.",
            "..64444446..",
            "...611116...",
            "..64....46..",
            "...44..44...",
            "............",
        ])

    public static let pipHurt = PixelSprite(
        rows: [
            "....6666....",
            "...655556...",
            "..65555556..",
            "..68333386..",
            "..63888836..",
            "..68333386..",
            "..64444446..",
            ".461111164..",
            ".461111164..",
            ".6111881116.",
            ".6111881116.",
            ".6111111116.",
            "..64444446..",
            ".611....116.",
            "644......446",
            "44........44",
        ])

    public static let canister = PixelSprite(
        rows: [
            "..666666..",
            ".68888886.",
            "6889999886",
            "6889999886",
            "6888888886",
            "6888888886",
            "6889999886",
            "6889999886",
            ".68888886.",
            "..666666..",
        ])

    public static let core = PixelSprite(
        rows: [
            "....666666....",
            "...69999996...",
            "..6999999996..",
            "..6997777996..",
            "..6997777996..",
            "..6999999996..",
            "..6999999996..",
            "..6999999996..",
            "...69999996...",
            "....666666....",
            "....644446....",
            "....644446....",
            "...64444446...",
            "....666666....",
        ])

    public static let chip = PixelSprite(
        rows: [
            "666666666666",
            "644449944446",
            "644449944446",
            "644499944446",
            "644999994446",
            "644449994446",
            "644444944446",
            "644444944446",
            "644444444446",
            "666666666666",
        ])
}
