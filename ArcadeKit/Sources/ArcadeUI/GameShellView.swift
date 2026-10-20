import ArcadeCore
import SwiftUI

public struct GameShellView: View {
    @State private var session: GameSession
    @State private var isShowingSettings = false

    public init(session: GameSession = GameSession()) {
        _session = State(initialValue: session)
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            MetalGameView(session: session)
            HUDView { isShowingSettings = true }
            PhaseOverlay()
            #if os(iOS)
                VStack {
                    Spacer()
                    TouchControlsView()
                }
            #endif
        }
        .environment(session)
        .background(.black)
        .keyboardControls(input: session.input) { session.togglePause() }
        .sheet(isPresented: $isShowingSettings) {
            RenderSettingsView().environment(session)
        }
        .statusBarHiddenIfAvailable()
    }
}

private struct PhaseOverlay: View {
    @Environment(GameSession.self) private var session

    var body: some View {
        Group {
            switch session.phase {
            case .attract:
                AttractPanel()
            case .ready:
                BannerText("GET READY", tint: ArcadePalette.visor.color)
            case .stageClear:
                BannerText("SPIRE SECURED", tint: ArcadePalette.shell.color)
            case .gameOver:
                GameOverPanel()
            case .playing, .dying:
                if session.isPaused {
                    BannerText("PAUSED", tint: .white)
                }
            }
        }
        .animation(.snappy, value: session.phase)
    }
}

private struct BannerText: View {
    let text: String
    let tint: Color

    init(_ text: String, tint: Color) {
        self.text = text
        self.tint = tint
    }

    var body: some View {
        Text(text)
            .font(.system(size: 28, weight: .black, design: .monospaced))
            .foregroundStyle(tint)
            .shadow(color: .black, radius: 0, x: 2, y: 2)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(.black.opacity(0.55), in: .rect(cornerRadius: 12))
    }
}

private struct AttractPanel: View {
    @Environment(GameSession.self) private var session

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text("SCRAP SPIRE")
                    .font(.system(size: 36, weight: .black, design: .monospaced))
                    .foregroundStyle(ArcadePalette.visor.color)
                    .shadow(color: ArcadePalette.accent.color, radius: 0, x: 3, y: 3)
                Text("Climb the tower. Dodge the drop.")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Button {
                session.start()
            } label: {
                Text("INSERT CREDIT")
                    .font(.system(size: 16, weight: .heavy, design: .monospaced))
                    .padding(.horizontal, 26)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(ArcadePalette.accent.color)
            Text("Arrows or WASD to move · Space to jump · P to pause")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .background(.black.opacity(0.62), in: .rect(cornerRadius: 18))
    }
}

private struct GameOverPanel: View {
    @Environment(GameSession.self) private var session

    var body: some View {
        VStack(spacing: 14) {
            Text("GAME OVER")
                .font(.system(size: 30, weight: .black, design: .monospaced))
                .foregroundStyle(ArcadePalette.accent.color)
            VStack(spacing: 2) {
                Text("SCORE \(session.board.score)")
                Text("BEST \(session.board.highScore)")
            }
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            Button("PLAY AGAIN") { session.start() }
                .buttonStyle(.borderedProminent)
                .tint(ArcadePalette.shell.color)
                .font(.system(size: 14, weight: .heavy, design: .monospaced))
        }
        .padding(28)
        .background(.black.opacity(0.62), in: .rect(cornerRadius: 18))
    }
}

extension View {
    func statusBarHiddenIfAvailable() -> some View {
        #if os(iOS)
            statusBarHidden()
        #else
            self
        #endif
    }
}
