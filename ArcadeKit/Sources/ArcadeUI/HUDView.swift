import ArcadeCore
import SwiftUI

struct HUDView: View {
    @Environment(GameSession.self) private var session
    let onSettings: () -> Void

    private var showsSettingsButton: Bool {
        #if os(tvOS)
            !session.phase.isInteractive
        #else
            true
        #endif
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                ScoreColumn(title: "SCORE", value: session.board.score)
                Spacer(minLength: 12)
                StageBadge(stage: session.board.stage)
                Spacer(minLength: 12)
                ScoreColumn(title: "BEST", value: session.board.highScore, alignment: .trailing)
            }
            .allowsHitTesting(false)
            HStack(spacing: 12) {
                BonusBar(fraction: session.world.bonusFraction)
                    .allowsHitTesting(false)
                if showsSettingsButton {
                    SettingsButton(action: onSettings)
                }
            }
            .padding(.top, 8)
            Spacer()
            HStack {
                LivesRow(lives: session.board.lives)
                Spacer()
                if session.world.climber.hasOverclock {
                    OverclockTag()
                }
            }
            .allowsHitTesting(false)
        }
        .padding(.horizontal, HUDMetrics.margin)
        .padding(.vertical, HUDMetrics.size(12))
    }
}

private struct SettingsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: HUDMetrics.size(14), weight: .semibold))
                .frame(width: HUDMetrics.size(30), height: HUDMetrics.size(30))
                .background(.white.opacity(0.1), in: .circle)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.85))
        .accessibilityLabel("Display settings")
    }
}

private struct ScoreColumn: View {
    let title: String
    let value: Int
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title)
                .font(.system(size: HUDMetrics.size(10), weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(value, format: .number.grouping(.never))
                .font(.system(size: HUDMetrics.size(22), weight: .heavy, design: .monospaced))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .monospacedDigit()
        }
    }
}

private struct StageBadge: View {
    let stage: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("SPIRE")
                .font(.system(size: HUDMetrics.size(10), weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
            Text("\(stage)")
                .font(.system(size: HUDMetrics.size(18), weight: .heavy, design: .monospaced))
                .foregroundStyle(ArcadePalette.visor.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.black.opacity(0.35), in: .rect(cornerRadius: 8))
    }
}

private struct BonusBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.12))
                Capsule(style: .continuous)
                    .fill(color.gradient)
                    .frame(width: max(proxy.size.width * fraction, 0))
            }
        }
        .frame(height: HUDMetrics.size(5))
        .animation(.linear(duration: 0.1), value: fraction)
    }

    private var color: Color {
        if fraction < 0.2 { return ArcadePalette.accent.color }
        if fraction < 0.45 { return ArcadePalette.signal.color }
        return ArcadePalette.shell.color
    }
}

private struct LivesRow: View {
    let lives: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<max(lives, 0), id: \.self) { _ in
                Circle()
                    .fill(ArcadePalette.shell.color)
                    .frame(width: HUDMetrics.size(9), height: HUDMetrics.size(9))
                    .overlay(Circle().stroke(.black.opacity(0.5), lineWidth: 1))
            }
        }
    }
}

private struct OverclockTag: View {
    var body: some View {
        Text("OVERCLOCK")
            .font(.system(size: HUDMetrics.size(10), weight: .heavy, design: .monospaced))
            .foregroundStyle(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(ArcadePalette.signal.color, in: .capsule)
            .transition(.scale.combined(with: .opacity))
    }
}

extension PixelColor {
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
