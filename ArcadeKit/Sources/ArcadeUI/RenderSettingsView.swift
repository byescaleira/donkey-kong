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
                        Slider(value: $session.settings.crt.scanlineStrength, in: 0...0.6) {
                            Text("Scanlines")
                        }
                        Slider(value: $session.settings.crt.bloom, in: 0...1) { Text("Bloom") }
                        Slider(value: $session.settings.crt.curvature, in: 0...0.06) {
                            Text("Curvature")
                        }
                        Slider(value: $session.settings.crt.vignette, in: 0...0.6) {
                            Text("Vignette")
                        }
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
