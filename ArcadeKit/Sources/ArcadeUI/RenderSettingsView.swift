import ArcadeCore
import ArcadeRender
import SwiftUI

public struct RenderSettingsView: View {
    @Environment(GameSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        @Bindable var session = session
        NavigationStack {
            Form {
                Section {
                    Picker("Upscaling", selection: $session.settings.upscaling) {
                        ForEach(UpscalingMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    LabeledContent("Render") { Text(session.stats.renderDescription) }
                    LabeledContent("Output") { Text(session.stats.outputDescription) }
                    LabeledContent("MetalFX") {
                        Text(session.stats.usesMetalFX ? "Active" : "Bypassed")
                            .foregroundStyle(session.stats.usesMetalFX ? .green : .secondary)
                    }
                } header: {
                    Text("Resolution")
                } footer: {
                    Text(
                        "The scene renders below the display resolution and MetalFX reconstructs it up to 4K."
                    )
                }

                Section("Frame rate") {
                    Picker("Target", selection: $session.settings.framesPerSecond) {
                        Text("60 fps").tag(60)
                        Text("120 fps").tag(120)
                    }
                    LabeledContent("Measured") {
                        Text("\(session.stats.framesPerSecond, specifier: "%.0f") fps")
                            .monospacedDigit()
                    }
                }

                Section("Cabinet look") {
                    Toggle("CRT effects", isOn: $session.settings.crt.isEnabled)
                    if session.settings.crt.isEnabled {
                        EffectLevel(
                            title: "Scanlines", value: $session.settings.crt.scanlineStrength,
                            range: 0...0.6)
                        EffectLevel(title: "Bloom", value: $session.settings.crt.bloom, range: 0...1)
                        EffectLevel(
                            title: "Curvature", value: $session.settings.crt.curvature,
                            range: 0...0.06)
                        EffectLevel(
                            title: "Vignette", value: $session.settings.crt.vignette, range: 0...0.6)
                    }
                }
            }
            .navigationTitle("Display")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct EffectLevel: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        #if os(tvOS)
            Picker(title, selection: step) {
                Text("Off").tag(0)
                Text("Low").tag(1)
                Text("Medium").tag(2)
                Text("High").tag(3)
            }
        #else
            Slider(value: $value, in: range) { Text(title) }
        #endif
    }

    private var step: Binding<Int> {
        Binding(
            get: {
                let span = range.upperBound - range.lowerBound
                guard span > 0 else { return 0 }
                let fraction = (value - range.lowerBound) / span
                return Int((fraction * 3).rounded().clamped(to: 0...3))
            },
            set: { newValue in
                let span = range.upperBound - range.lowerBound
                value = range.lowerBound + span * Double(newValue) / 3
            })
    }
}
