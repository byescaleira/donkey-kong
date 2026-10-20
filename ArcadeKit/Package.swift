// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ArcadeKit",
    defaultLocalization: "en",
    platforms: [.iOS("26.0"), .macOS("26.0"), .tvOS("26.0")],
    products: [
        .library(name: "ArcadeKit", targets: ["ArcadeUI"]),
        .library(name: "ArcadeCore", targets: ["ArcadeCore"]),
        .executable(name: "ArcadeShot", targets: ["ArcadeShot"]),
    ],
    targets: [
        .target(name: "ArcadeCore"),
        .target(name: "ArcadeAudio", dependencies: ["ArcadeCore"]),
        .target(name: "ArcadeScene", dependencies: ["ArcadeCore"]),
        .target(name: "ArcadeRender", dependencies: ["ArcadeCore", "ArcadeScene"]),
        .target(
            name: "ArcadeUI",
            dependencies: ["ArcadeCore", "ArcadeAudio", "ArcadeScene", "ArcadeRender"]),
        .executableTarget(
            name: "ArcadeShot",
            dependencies: ["ArcadeCore", "ArcadeAudio", "ArcadeScene", "ArcadeRender"]),
        .testTarget(name: "ArcadeCoreTests", dependencies: ["ArcadeCore"]),
        .testTarget(name: "ArcadeAudioTests", dependencies: ["ArcadeCore", "ArcadeAudio"]),
        .testTarget(name: "ArcadeSceneTests", dependencies: ["ArcadeCore", "ArcadeScene"]),
        .testTarget(name: "ArcadeRenderTests", dependencies: ["ArcadeCore", "ArcadeRender"]),
    ]
)
